unit crypt3;

(*
 * UFC-crypt: ultra fast crypt(3) implementation
 *
 * Copyright (C) 1991, 1992, Michael Glad, email: glad@daimi.aau.dk
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 * @(#)crypt_util.c 2.29 01/23/92
 *
 * Support routines
 *
 *)
 
{
  2002/12/08
  translated by Wolfy
}

interface

uses
  Windows,Sysutils;

type
  punsigned = ^unsigned;
  unsigned = UINT;
  int = integer;

  psalt = ^tsalt;
  tsalt = array[0..1] of unsigned;

  poutbuf = ^toutbuf;
  toutbuf = array[0..pred(14)] of char;

  TCrypt3 = class(TObject)
  private
    e_inverse: array [0..Pred(64)] of int;
    ufc_keytab: array [0..Pred(16),0..Pred(2)] of UINT;
    ufc_sb0: array [0..Pred(8192)] of UINT;
    ufc_sb1: array [0..Pred(8192)] of UINT;
    ufc_sb2: array [0..Pred(8192)] of UINT;
    ufc_sb3: array [0..Pred(8192)] of UINT;
    sb: array [0..Pred(4)] of pUINT;
    eperm32tab: array [0..Pred(4),0..Pred(256),0..Pred(2)] of unsigned;
    do_pc1: array [0..Pred(8),0..Pred(2),0..Pred(128)] of unsigned;
    do_pc2: array [0..Pred(8),0..Pred(128)] of unsigned;
    efp: array [0..Pred(16),0..Pred(64),0..Pred(2)] of unsigned;

    initialized: int;
    current_salt: array [0..Pred(3)] of char;
    current_saltbits: unsigned;
    direction: integer;

    procedure init_des();
    procedure setup_salt(s: pchar);
    procedure ufc_mk_keytab(key: pchar);
    function ufc_dofinalperm(l1,l2,r1,r2: unsigned): tsalt;
    function ufc_doit(l1,l2,r1,r2,itr: unsigned): tsalt;
  public
    constructor Create;
    function Crypt(key,salt: string): string;
  end;

implementation

type
  pulong_array = ^tulong_array;
  tulong_array = array[0..pred(maxint div sizeof(UINT))] of UINT;

  punsigned_array = ^tunsigned_array;
  tunsigned_array = array[0..pred(maxint div sizeof(unsigned))] of unsigned;

const
  sbox: array [0..Pred(8),0..Pred(4),0..Pred(16)] of int = (((14,4,13,1,2,15,11,8,3,10,6,12,5,9,0,7),(0,15,7,4,14,2,13,1,10,6,12,11,9,5,3,8),(4,1,14,8,13,6,2,11,15,12,9,7,3,10,5,0),(15,12,8,2,4,9,1,7,5,11,3,14,10,0,6,13)),
    ((15,1,8,14,6,11,3,4,9,7,2,13,12,0,5,10),(3,13,4,7,15,2,8,14,12,0,1,10,6,9,11,5),(0,14,7,11,10,4,13,1,5,8,12,6,9,3,2,15),(13,8,10,1,3,15,4,2,11,6,7,12,0,5,14,9)),
    ((10,0,9,14,6,3,15,5,1,13,12,7,11,4,2,8),(13,7,0,9,3,4,6,10,2,8,5,14,12,11,15,1),(13,6,4,9,8,15,3,0,11,1,2,12,5,10,14,7),(1,10,13,0,6,9,8,7,4,15,14,3,11,5,2,12)),
    ((7,13,14,3,0,6,9,10,1,2,8,5,11,12,4,15),(13,8,11,5,6,15,0,3,4,7,2,12,1,10,14,9),(10,6,9,0,12,11,7,13,15,1,3,14,5,2,8,4),(3,15,0,6,10,1,13,8,9,4,5,11,12,7,2,14)),
    ((2,12,4,1,7,10,11,6,8,5,3,15,13,0,14,9),(14,11,2,12,4,7,13,1,5,0,15,10,3,9,8,6),(4,2,1,11,10,13,7,8,15,9,12,5,6,3,0,14),(11,8,12,7,1,14,2,13,6,15,0,9,10,4,5,3)),
    ((12,1,10,15,9,2,6,8,0,13,3,4,14,7,5,11),(10,15,4,2,7,12,9,5,6,1,13,14,0,11,3,8),(9,14,15,5,2,8,12,3,7,0,4,10,1,13,11,6),(4,3,2,12,9,5,15,10,11,14,1,7,6,0,8,13)),
    ((4,11,2,14,15,0,8,13,3,12,9,7,5,10,6,1),(13,0,11,7,4,9,1,10,14,3,5,12,2,15,8,6),(1,4,11,13,12,3,7,14,10,15,6,8,0,5,9,2),(6,11,13,8,1,4,10,7,9,5,0,15,14,2,3,12)),
    ((13,2,8,4,6,15,11,1,10,9,3,14,5,0,12,7),(1,15,13,8,10,3,7,4,12,5,6,11,0,14,9,2),(7,11,4,1,9,12,14,2,0,6,10,13,15,3,5,8),(2,1,14,7,4,10,8,13,15,12,9,0,3,5,6,11)));
  pc1: array [0..Pred(56)] of int = (57,49,41,33,25,17,9,1,58,50,42,34,26,18,10,2,59,51,43,35,27,19,11,3,60,52,44,36,63,55,47,39,31,23,15,7,62,54,46,38,30,22,14,6,61,53,45,37,29,21,13,5,28,20,12,4);
  rots: array [0..Pred(16)] of int = (1,1,2,2,2,2,2,2,1,2,2,2,2,2,2,1);
  pc2: array [0..Pred(48)] of int = (14,17,11,24,1,5,3,28,15,6,21,10,23,19,12,4,26,8,16,7,27,20,13,2,41,52,31,37,47,55,30,40,51,45,33,48,44,49,39,56,34,53,46,42,50,36,29,32);
  esel: array [0..Pred(48)] of int = (32,1,2,3,4,5,4,5,6,7,8,9,8,9,10,11,12,13,12,13,14,15,16,17,16,17,18,19,20,21,20,21,22,23,24,25,24,25,26,27,28,29,28,29,30,31,32,1);

  perm32: array [0..Pred(32)] of int = (16,7,20,21,29,12,28,17,1,15,23,26,5,18,31,10,2,8,24,14,32,27,3,9,19,13,30,6,22,11,4,25);
  //initial_perm: array [0..Pred(64)] of int = (58,50,42,34,26,18,10,2,60,52,44,36,28,20,12,4,62,54,46,38,30,22,14,6,64,56,48,40,32,24,16,8,57,49,41,33,25,17,9,1,59,51,43,35,27,19,11,3,61,53,45,37,29,21,13,5,63,55,47,39,31,23,15,7);
  final_perm: array [0..Pred(64)] of int = (40,8,48,16,56,24,64,32,39,7,47,15,55,23,63,31,38,6,46,14,54,22,62,30,37,5,45,13,53,21,61,29,36,4,44,12,52,20,60,28,35,3,43,11,51,19,59,27,34,2,42,10,50,18,58,26,33,1,41,9,49,17,57,25);
  bytemask: array [0..Pred(8)] of Byte = ($80,$40,$20,$10,$08,$04,$02,$01);
  longmask: array [0..Pred(32)] of UINT = ($80000000,$40000000,$20000000,$10000000,$08000000,$04000000,$02000000,$01000000,$00800000,$00400000,$00200000,$00100000,$00080000,$00040000,$00020000,$00010000,$00008000,$00004000,$00002000,$00001000,$00000800,$00000400,$00000200,$00000100,$00000080,$00000040,$00000020,$00000010,$00000008,$00000004,$00000002,$00000001);


function ascii_to_bin(c: char): UINT;
begin
  if (c)>='a' then
    result:= (byte(c)-59)
  else if (c)>='A' then
    result:= (byte(c)-53)
  else
    result:= byte(c)-byte('.');
end;

function bin_to_ascii(c: UINT): char;
begin
  if (c)>=38 then
    result:= char(((c)-38+byte('a')))
  else if (c)>=12 then
    result:= char((c)-12+byte('A'))
  else
    result:= char(c+byte('.'));
end;

function BITMASK(i: UINT): UINT;
begin
  if i<12 then
    result:= (1 shl (11-(i) mod 12+3)) shl 16
  else
    result:= (1 shl (11-(i) mod 12+3)) shl 0;
end;

procedure clearmem(start: pchar; cnt: int);
begin
  FillChar(start^,cnt,0);
end;

function s_lookup(i: UINT;  s: UINT): UINT;
begin
  result:= sbox[(i)][(((s) shr 4) and $2) or ((s) and $1)][((s) shr 1) and $f];
end;

procedure TCrypt3.init_des();
var
comes_from_bit,bit,sg: integer;
j,mask1_a,mask2_a: unsigned;

mask1_b,comes_from: unsigned;

j1,j2,s1,s2: int;
to_permute,inx: unsigned;

o_bit,o_long: integer;
word_value,mask1_c,mask2_c: unsigned;
comes_from_f_bit,comes_from_e_bit,
comes_from_word,bit_within_word: integer;
begin

  for bit:=0 to Pred(56) do
  begin
    comes_from_bit:= pc1[bit]-1;
    mask1_a:= bytemask[comes_from_bit mod 8+1];
    mask2_a:= longmask[bit mod 28+4];
    for j:=0 to Pred(128) do
    begin
      if ((j and mask1_a) <> 0) then
      begin
        do_pc1[comes_from_bit div 8][bit div 28][j]:= do_pc1[comes_from_bit div 8][bit div 28][j] or (mask2_a);
      end;
    end;
  end;
  
  for bit:=0 to Pred(48)do
  begin 
    comes_from_bit:= pc2[bit]-1; 
    mask1_a:= bytemask[comes_from_bit mod 7+1];
    mask2_a:= BITMASK(bit mod 24);
    for j:=0 to Pred(128) do
    begin
      if ((j and mask1_a) <> 0) then
      begin
        do_pc2[comes_from_bit div 7][j]:= do_pc2[comes_from_bit div 7][j] or (mask2_a);
      end;
    end;
  end;

  clearmem(pchar(@eperm32tab),sizeof(eperm32tab));

  for bit:=0 to Pred(48) do
  begin      

    comes_from:= perm32[esel[bit]-1]-1;
    mask1_b:= bytemask[comes_from mod 8];
    for j:= pred(256) downto 0 do
    begin
      if ((j and mask1_b) <> 0) then
      begin
        eperm32tab[comes_from div 8][j][bit div 24]:= eperm32tab[comes_from div 8][j][bit div 24] or (BITMASK(bit mod 24));
      end;
    end;
  end;

  for sg:=0 to Pred(4) do
  begin

    for j1:=0 to Pred(64) do
    begin 
      s1:= s_lookup(2*sg,j1); 
      for j2:=0 to Pred(64)do
      begin
        s2:= s_lookup(2*sg+1,j2);

        to_permute:= ((s1 shl 4) or s2) shl (24-8*sg);
        inx:= ((j1 shl 6) or j2) shl 1;
        pulong_array(sb[sg])[inx]:=   eperm32tab[0][(to_permute shr 24) and $ff][0];
        pulong_array(sb[sg])[inx+1]:= eperm32tab[0][(to_permute shr 24) and $ff][1];
        pulong_array(sb[sg])[inx]:=   pulong_array(sb[sg])[inx]     or (eperm32tab[1][(to_permute shr 16) and $ff][0]);
        pulong_array(sb[sg])[inx+1]:= pulong_array(sb[sg])[inx+1] or (eperm32tab[1][(to_permute shr 16) and $ff][1]);
        pulong_array(sb[sg])[inx]:=   pulong_array(sb[sg])[inx]     or (eperm32tab[2][(to_permute shr 8) and $ff][0]);
        pulong_array(sb[sg])[inx+1]:= pulong_array(sb[sg])[inx+1] or (eperm32tab[2][(to_permute shr 8) and $ff][1]);
        pulong_array(sb[sg])[inx]:=   pulong_array(sb[sg])[inx]     or (eperm32tab[3][(to_permute) and $ff][0]);
        pulong_array(sb[sg])[inx+1]:= pulong_array(sb[sg])[inx+1] or (eperm32tab[3][(to_permute) and $ff][1]);
      end;
    end;
  end;
  
  for bit:= pred(48) downto 0 do
  begin
    e_inverse[esel[bit]-1]:= bit;
    e_inverse[esel[bit]-1+32]:= bit+48;
  end;

  clearmem(pchar(@efp),sizeof(efp));
 
  for bit:=0 to Pred(64) do
  begin   
    
    o_long:= bit div 32; 
    o_bit:= bit mod 32; 
    comes_from_f_bit:= final_perm[bit]-1;
    comes_from_e_bit:= e_inverse[comes_from_f_bit]; 
    comes_from_word:= comes_from_e_bit div 6; 
    bit_within_word:= comes_from_e_bit mod 6; 
    mask1_c:= longmask[bit_within_word+26];
    mask2_c:= longmask[o_bit];

    
    for word_value:= pred(64) downto 0 do
    begin 
      if ((word_value and mask1_c) <> 0) then
      begin
        efp[comes_from_word][word_value][o_long]:= efp[comes_from_word][word_value][o_long] or (mask2_c);
      end;
    end;
  end;
  inc(initialized); 
end;

procedure shuffle_sb(k: pUINT; saltbits: unsigned);
var
  j: unsigned;
  x: UINT;
begin
  for j:= pred(4096) downto 0 do
  begin
    x:= (pulong_array(k)[0] xor pulong_array(k)[1]) and UINT(saltbits);
    k^ := k^ xor x; inc(k);
    k^ := k^ xor x; inc(k);
  end;
end;


procedure TCrypt3.setup_salt(s: pchar); 
var
  i,j,saltbits: unsigned; 
  c: integer;
begin 
  if (0=initialized) then
    init_des();
  
  if (s[0]=current_salt[0])and(s[1]=current_salt[1]) then
    exit;
  
  current_salt[0]:= s[0]; 
  current_salt[1]:= s[1];

  saltbits:= 0;

  for i:=0 to Pred(2) do
  begin
    c := ascii_to_bin(s[i]);

    if (c<0)or(c>63) then
      c:= 0;

    for j:=0 to Pred(6) do
    begin
      if (((c shr j) and $1) <> 0) then
      begin
        saltbits:= saltbits or (BITMASK(6*i+j));
      end;
    end;
  end;

  shuffle_sb(@ufc_sb0,current_saltbits xor saltbits);
  shuffle_sb(@ufc_sb1,current_saltbits xor saltbits);
  shuffle_sb(@ufc_sb2,current_saltbits xor saltbits);
  shuffle_sb(@ufc_sb3,current_saltbits xor saltbits);
  current_saltbits:= saltbits;
end;

procedure TCrypt3.ufc_mk_keytab(key: pchar);
var
  v1,v2: unsigned;
  k1: punsigned;
  i: integer;
  v: UINT;
  k2: pUINT;
begin 
  k2 := @ufc_keytab[0][0];
  v1:= 0;
  v2:= 0;
  k1:= @do_pc1[0][0][0];
  for i:= pred(8) downto 0 
  do
  begin 
    v1:= v1 or (pulong_array(k1)[byte(key^) and $7f]);
    inc(k1,128);
    v2:= v2 or (pulong_array(k1)[byte(key^) and $7f]);     
    inc(k1,128);
    inc(key);
  end;

  for i:=0 to Pred(16) do
  begin
    k1:=  @do_pc2[0][0];
    v1:= (v1 shl rots[i]) or (v1 shr (28-rots[i]));
    v:= punsigned_array(k1)[(v1 shr 21) and $7f];
    inc(k1,128);
    v:= v or (punsigned_array(k1)[(v1 shr 14) and $7f]);
    inc(k1,128);
    v:= v or (punsigned_array(k1)[(v1 shr 7) and $7f]);
    inc(k1,128);
    v:= v or (punsigned_array(k1)[(v1) and $7f]);
    inc(k1,128);
    k2^ := v; inc(k2);
    v:= 0;

    v2:= (v2 shl rots[i]) or (v2 shr (28-rots[i]));
    v:= v or (punsigned_array(k1)[(v2 shr 21) and $7f]);
    inc(k1,128);
    v:= v or (punsigned_array(k1)[(v2 shr 14) and $7f]);
    inc(k1,128);
    v:= v or (punsigned_array(k1)[(v2 shr 7) and $7f]);
    inc(k1,128);
    v:= v or (punsigned_array(k1)[(v2) and $7f]);
    k2^ := v; inc(k2); 
  end;
  
  direction:= 0; 
  
end;

function TCrypt3.ufc_dofinalperm(l1,l2,r1,r2: unsigned): tsalt;
var
  v1,v2,x: unsigned;
begin 
  x:= (l1 xor l2) and current_saltbits; 
  l1:= l1 xor (x); 
  l2:= l2 xor (x); 
  x:= (r1 xor r2) and current_saltbits; 
  r1:= r1 xor (x); 
  r2:= r2 xor (x); 
  v1:=0; v2:=0; 
  l1:= l1 shr (3); 
  l2:= l2 shr (3); 
  r1:= r1 shr (3); 
  r2:= r2 shr (3); 
  v1:= v1 or (efp[15][r2 and $3f][0]); 
  v2:= v2 or (efp[15][r2 and $3f][1]); 
  r2 := r2 shr 6;
  v1:= v1 or (efp[14][(r2) and $3f][0]); 
  v2:= v2 or (efp[14][r2 and $3f][1]); 
  r2 := r2 shr 10;
  v1:= v1 or (efp[13][(r2) and $3f][0]); 
  v2:= v2 or (efp[13][r2 and $3f][1]); 
  r2 := r2 shr 6;
  v1:= v1 or (efp[12][(r2) and $3f][0]); 
  v2:= v2 or (efp[12][r2 and $3f][1]); 
  v1:= v1 or (efp[11][r1 and $3f][0]); 
  v2:= v2 or (efp[11][r1 and $3f][1]); 
  r1 :=r1 shr 6;
  v1:= v1 or (efp[10][(r1) and $3f][0]); 
  v2:= v2 or (efp[10][r1 and $3f][1]); 
  r1 := r1 shr 10;
  v1:= v1 or (efp[9][(r1) and $3f][0]); 
  v2:= v2 or (efp[9][r1 and $3f][1]); 
  r1 := r1 shr 6;
  v1:= v1 or (efp[8][(r1) and $3f][0]); 
  v2:= v2 or (efp[8][r1 and $3f][1]); 
  v1:= v1 or (efp[7][l2 and $3f][0]); 
  v2:= v2 or (efp[7][l2 and $3f][1]); 
  l2 := l2 shr 6;
  v1:= v1 or (efp[6][(l2) and $3f][0]); 
  v2:= v2 or (efp[6][l2 and $3f][1]); 
  l2 := l2 shr 10;
  v1:= v1 or (efp[5][(l2) and $3f][0]); 
  v2:= v2 or (efp[5][l2 and $3f][1]); 
  l2 := l2 shr 6;
  v1:= v1 or (efp[4][(l2) and $3f][0]); 
  v2:= v2 or (efp[4][l2 and $3f][1]); 
  v1:= v1 or (efp[3][l1 and $3f][0]); 
  v2:= v2 or (efp[3][l1 and $3f][1]); 
  l1 := l1 shr 6;
  v1:= v1 or (efp[2][(l1) and $3f][0]); 
  v2:= v2 or (efp[2][l1 and $3f][1]); 
  l1 :=l1 shr 10 ;
  v1:= v1 or (efp[1][(l1) and $3f][0]); 
  v2:= v2 or (efp[1][l1 and $3f][1]); 
  l1 := l1 shr 6;
  v1:= v1 or (efp[0][(l1) and $3f][0]); 
  v2:= v2 or (efp[0][l1 and $3f][1]); 
  result[0]:= v1;
  result[1]:= v2;
end;

function output_conversion(v1,v2: unsigned;
  salt: pchar): toutbuf; 
var
  outbuf: poutbuf;
  i,s: integer;
begin 
  outbuf := @result;
  outbuf[0]:= salt[0]; 
  if salt[1] <> #0 then
    outbuf[1]:= salt[1]
  else
    outbuf[1] := salt[0];

  for i:=0 to Pred(5) do
    outbuf[i+2]:= bin_to_ascii((v1 shr (26-6*i)) and $3f); 
  
  s:= (v2 and $f) shl 2; 
  v2:= (v2 shr 2) or ((v1 and $3) shl 30); 
  
  for i:=5 to Pred(10) do
    outbuf[i+2]:= bin_to_ascii((v2 shr (56-6*i)) and $3f); 
  
  outbuf[12]:= bin_to_ascii(s); 
  outbuf[13]:= #0; 
end;


function SBA(sb: pUINT; v: UINT): UINT;
begin
  inc(pchar(sb),v);
  result := puint(sb)^;
end;

function TCrypt3.ufc_doit(l1,l2,r1,r2,itr: unsigned): tsalt;
var
  i: integer;
  s: UINT; 
  k: pUINT; 
begin 
  while true do
  begin
    if itr = 0 then
      break;

    dec(itr);     

    k:= @ufc_keytab[0][0]; 
    for i:= pred(8) downto 0 do 
    begin 
      s:= k^ xor r1;
      inc(k); 
      l1:= l1 xor (SBA(@ufc_sb1,s and $ffff));
      l2:= l2 xor (SBA(@ufc_sb1,(s and $ffff)+4));

      s := s shr 16;
      l1:= l1 xor (SBA(@ufc_sb0,s));
      l2:= l2 xor (SBA(@ufc_sb0,(s)+4));
      s:= k^ xor r2;
      inc(k);

      l1:= l1 xor (SBA(@ufc_sb3,s and $ffff));
      l2:= l2 xor (SBA(@ufc_sb3,(s and $ffff)+4));

      s := s shr 16;
      l1:= l1 xor (SBA(@ufc_sb2,s));
      l2:= l2 xor (SBA(@ufc_sb2,(s)+4));

      s:= k^ xor l1;
      inc(k);
      r1:= r1 xor (SBA(@ufc_sb1,s and $ffff));
      r2:= r2 xor (SBA(@ufc_sb1,(s and $ffff)+4));

      s := s shr 16;
      r1:= r1 xor (SBA(@ufc_sb0,s));
      r2:= r2 xor (SBA(@ufc_sb0,(s)+4));
      s:= k^ xor l2;
      inc(k);
      
      r1:= r1 xor (SBA(@ufc_sb3,s and $ffff));
      r2:= r2 xor (SBA(@ufc_sb3,(s and $ffff)+4));

      s := s shr 16;
      r1:= r1 xor (SBA(@ufc_sb2,s));
      r2:= r2 xor (SBA(@ufc_sb2,(s)+4));

    end;
    s:= l1;
    l1:= r1;
    r1:= s;
    s:= l2;
    l2:= r2;
    r2:= s;
  end;

  result:= ufc_dofinalperm(l1,l2,r1,r2);
end;

constructor TCrypt3.Create;
begin
  inherited Create;
  sb[0] := @ufc_sb0;
  sb[1] := @ufc_sb1;
  sb[2] := @ufc_sb2;
  sb[3] := @ufc_sb3;
  initialized := 0;
  current_salt := '&&'#0;
  current_saltbits := 0;
  direction := 0;
end;

function TCrypt3.crypt(key,salt: string): string;
var
  s: tsalt;
  ktab: array [0..Pred(9)] of char;
  output: toutbuf;
begin
  setup_salt(pchar(salt));
  clearmem(ktab,sizeof(ktab));

  strlcopy(ktab,pchar(key),8);
  ufc_mk_keytab(ktab);

  s:= ufc_doit(0,0,0,0,25);

  output := output_conversion(s[0],s[1],pchar(salt));
  result := string(output);
end;

end.
