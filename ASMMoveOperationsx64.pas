// ###################################################################
// #### This file is part of the mathematics library project, and is
// #### offered under the licence agreement described on
// #### http://www.mrsoft.org/
// ####
// #### Copyright:(c) 2011, Michael R. . All rights reserved.
// ####
// #### Unless required by applicable law or agreed to in writing, software
// #### distributed under the License is distributed on an "AS IS" BASIS,
// #### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// #### See the License for the specific language governing permissions and
// #### limitations under the License.
// ###################################################################


unit ASMMoveOperationsx64;

// #################################################
// #### SSE optimized move oprationes
// #################################################

interface

{$IFDEF CPUX64}
{$DEFINE x64}
{$ENDIF}
{$IFDEF cpux86_64}
{$DEFINE x64}
{$ENDIF}
{$IFDEF x64}

uses MatrixConst;

procedure ASMMatrixCopyAlignedEvenW(Dest : PDouble; const destLineWidth : TASMNativeInt; src : PDouble; const srcLineWidth : TASMNativeInt; Width, Height : TASMNativeInt);
procedure ASMMatrixCopyUnAlignedEvenW(Dest : PDouble; const destLineWidth : TASMNativeInt; src : PDouble; const srcLineWidth : TASMNativeInt; Width, Height : TASMNativeInt);

procedure ASMMatrixCopyAlignedOddW(Dest : PDouble; const destLineWidth : TASMNativeInt; src : PDouble; const srcLineWidth : TASMNativeInt; Width, Height : TASMNativeInt);
procedure ASMMatrixCopyUnAlignedOddW(Dest : PDouble; const destLineWidth : TASMNativeInt; src : PDouble; const srcLineWidth : TASMNativeInt; Width, Height : TASMNativeInt);

procedure ASMRowSwapAlignedEvenW(A, B : PDouble; width : TASMNativeInt);
procedure ASMRowSwapUnAlignedEvenW(A, B : PDouble; width : TASMNativeInt);

procedure ASMRowSwapAlignedOddW(A, B : PDouble; width : TASMNativeInt);
procedure ASMRowSwapUnAlignedOddW(A, B : PDouble; width : TASMNativeInt);

procedure ASMInitMemAligned(A : PDouble; NumBytes : TASMNativeInt; const Value : double);

{$ENDIF}

implementation

{$IFDEF x64}

{$IFDEF FPC} {$ASMMODE intel} {$ENDIF}

// uses non temporal moves so the cache is not poisned
// rcx = A, rdx = NumBytes;
procedure ASMInitMemAligned(A : PDouble; NumBytes : TASMNativeInt; const Value : double);
{$IFDEF FPC}
begin
{$ENDIF}
     asm
        movddup xmm1, Value;

        mov r10, rdx;
        and r10, $FFFFFFFFFFFFFF80;
        jz @@loopUnrolledEnd;

        mov rax, rcx;
        imul r10, -1;
        sub rax, r10;

        @@loopUnrolled:
          movntdq [rax + r10], xmm1;
          movntdq [rax + r10 + 16], xmm1;
          movntdq [rax + r10 + 32], xmm1;
          movntdq [rax + r10 + 48], xmm1;
          movntdq [rax + r10 + 64], xmm1;
          movntdq [rax + r10 + 80], xmm1;
          movntdq [rax + r10 + 96], xmm1;
          movntdq [rax + r10 + 112], xmm1;

          add r10, 128;
        jnz @@loopUnrolled;

        @@loopUnrolledEnd:

        // last few bytes
        mov rax, rcx;
        mov r10, rdx;
        add rax, r10;
        and r10, $7F;
        jz @@exitProc;

        imul r10, -1;

        @@loop:
          movsd [rax + r10], xmm1;
          add r10, 8;
        jnz @@loop;

        @@exitProc:
     end;
{$IFDEF FPC}
end;
{$ENDIF}

procedure ASMRowSwapAlignedEvenW(A, B : PDouble; width : TASMNativeInt);
{$IFDEF FPC}
begin
{$ENDIF}
asm
   // note: RCX = a, RDX = b, R8 = width
   mov r10, width;
   shl r10, 3;
   imul r10, -1;

   sub rcx, r10;
   sub rdx, r10;

   @unrolloop:
     add r10, 64;
     jg @unrolloopend;

     // prefetch data...
     // prefetchw [rcx + r10];
     // prefetchw [rdx + r10];

     movdqa xmm0, [rcx + r10 - 64];
     movdqa xmm1, [rdx + r10 - 64];

     movdqa [rcx + r10 - 64], xmm1;
     movdqa [rdx + r10 - 64], xmm0;

     movdqa xmm2, [rcx + r10 - 48];
     movdqa xmm3, [rdx + r10 - 48];

     movdqa [rcx + r10 - 48], xmm3;
     movdqa [rdx + r10 - 48], xmm2;

     movdqa xmm4, [rcx + r10 - 32];
     movdqa xmm5, [rdx + r10 - 32];

     movdqa [rcx + r10 - 32], xmm5;
     movdqa [rdx + r10 - 32], xmm4;

     movdqa xmm6, [rcx + r10 - 16];
     movdqa xmm7, [rdx + r10 - 16];

     movdqa [rcx + r10 - 16], xmm7;
     movdqa [rdx + r10 - 16], xmm6;
   jmp @unrolloop;
   @unrolloopend:

   sub r10, 64;
   jz @endfunc;


   @loop:
     movdqa xmm0, [rcx + r10];
     movdqa xmm1, [rdx + r10];

     movdqa [rcx + r10], xmm1;
     movdqa [rdx + r10], xmm0;

     add r10, 16;
   jnz @loop;

   @endfunc:
{$IFDEF FPC}
end;
{$ENDIF}
end;

procedure ASMRowSwapUnAlignedEvenW(A, B : PDouble; width : TASMNativeInt);
{$IFDEF FPC}
begin
{$ENDIF}
asm
   // note: RCX = a, RDX = b, R8 = width
   mov r10, width;
   shl r10, 3;
   imul r10, -1;

   sub rcx, r10;
   sub rdx, r10;

   @unrolloop:
     add r10, 64;
     jg @unrolloopend;

     movdqu xmm0, [rcx + r10 - 64];
     movdqu xmm1, [rdx + r10 - 64];

     movdqu [rcx + r10 - 64], xmm1;
     movdqu [rdx + r10 - 64], xmm0;

     movdqu xmm2, [rcx + r10 - 48];
     movdqu xmm3, [rdx + r10 - 48];

     movdqu [rcx + r10 - 48], xmm3;
     movdqu [rdx + r10 - 48], xmm2;

     movdqu xmm4, [rcx + r10 - 32];
     movdqu xmm5, [rdx + r10 - 32];

     movdqu [rcx + r10 - 32], xmm5;
     movdqu [rdx + r10 - 32], xmm4;

     movdqu xmm6, [rcx + r10 - 16];
     movdqu xmm7, [rdx + r10 - 16];

     movdqu [rcx + r10 - 16], xmm7;
     movdqu [rdx + r10 - 16], xmm6;
   jmp @unrolloop;
   @unrolloopend:

   sub r10, 64;
   jz @endfunc;


   @loop:
     movdqu xmm0, [rcx + r10];
     movdqu xmm1, [rdx + r10];

     movdqu [rcx + r10], xmm1;
     movdqu [rdx + r10], xmm0;

     add r10, 16;
   jnz @loop;

   @endfunc:
{$IFDEF FPC}
end;
{$ENDIF}
end;

procedure ASMRowSwapAlignedOddW(A, B : PDouble; width : TASMNativeInt);
{$IFDEF FPC}
begin
{$ENDIF}
asm
   // note: RCX = a, RDX = b, R8 = width
   mov r10, width;
   dec r10;
   shl r10, 3;
   imul r10, -1;

   sub rcx, r10;
   sub rdx, r10;

   @unrolloop:
     add r10, 64;
     jg @unrolloopend;

     // prefetch data...
     // prefetchw [rcx + r10];
     // prefetchw [rdx + r10];

     movdqa xmm0, [rcx + r10 - 64];
     movdqa xmm1, [rdx + r10 - 64];

     movdqa [rcx + r10 - 64], xmm1;
     movdqa [rdx + r10 - 64], xmm0;

     movdqa xmm2, [rcx + r10 - 48];
     movdqa xmm3, [rdx + r10 - 48];

     movdqa [rcx + r10 - 48], xmm3;
     movdqa [rdx + r10 - 48], xmm2;

     movdqa xmm4, [rcx + r10 - 32];
     movdqa xmm5, [rdx + r10 - 32];

     movdqa [rcx + r10 - 32], xmm5;
     movdqa [rdx + r10 - 32], xmm4;

     movdqa xmm6, [rcx + r10 - 16];
     movdqa xmm7, [rdx + r10 - 16];

     movdqa [rcx + r10 - 16], xmm7;
     movdqa [rdx + r10 - 16], xmm6;
   jmp @unrolloop;
   @unrolloopend:

   sub r10, 64;
   jz @endfunc;


   @loop:
     movdqa xmm0, [rcx + r10];
     movdqa xmm1, [rdx + r10];

     movdqa [rcx + r10], xmm1;
     movdqa [rdx + r10], xmm0;

     add r10, 16;
   jnz @loop;

   @endfunc:

   // last swap
   movlpd xmm0, [rcx];
   movlpd xmm1, [rdx];

   movlpd [rcx], xmm1;
   movlpd [rdx], xmm0;
{$IFDEF FPC}
end;
{$ENDIF}
end;

procedure ASMRowSwapUnAlignedOddW(A, B : PDouble; width : TASMNativeInt);
{$IFDEF FPC}
begin
{$ENDIF}
asm
   // note: RCX = a, RDX = b, R8 = width
   mov r10, width;
   dec r10;
   shl r10, 3;
   imul r10, -1;

   sub rcx, r10;
   sub rdx, r10;

   @unrolloop:
     add r10, 64;
     jg @unrolloopend;

     movdqu xmm0, [rcx + r10 - 64];
     movdqu xmm1, [rdx + r10 - 64];

     movdqu [rcx + r10 - 64], xmm1;
     movdqu [rdx + r10 - 64], xmm0;

     movdqu xmm2, [rcx + r10 - 48];
     movdqu xmm3, [rdx + r10 - 48];

     movdqu [rcx + r10 - 48], xmm3;
     movdqu [rdx + r10 - 48], xmm2;

     movdqu xmm4, [rcx + r10 - 32];
     movdqu xmm5, [rdx + r10 - 32];

     movdqu [rcx + r10 - 32], xmm5;
     movdqu [rdx + r10 - 32], xmm4;

     movdqu xmm6, [rcx + r10 - 16];
     movdqu xmm7, [rdx + r10 - 16];

     movdqu [rcx + r10 - 16], xmm7;
     movdqu [rdx + r10 - 16], xmm6;
   jmp @unrolloop;
   @unrolloopend:

   sub r10, 64;
   jz @endfunc;


   @loop:
     movdqu xmm0, [rcx + r10];
     movdqu xmm1, [rdx + r10];

     movdqu [rcx + r10], xmm1;
     movdqu [rdx + r10], xmm0;

     add r10, 16;
   jnz @loop;

   @endfunc:

   // last swap
   movlpd xmm0, [rcx];
   movlpd xmm1, [rdx];

   movlpd [rcx], xmm1;
   movlpd [rdx], xmm0;
{$IFDEF FPC}
end;
{$ENDIF}
end;

procedure ASMMatrixCopyAlignedEvenW(Dest : PDouble; const destLineWidth : TASMNativeInt; src : PDouble; const srcLineWidth : TASMNativeInt; Width, Height : TASMNativeInt);
{$IFDEF FPC}
begin
{$ENDIF}
asm
   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth
   //iters := -width*sizeof(double);
   mov r10, width;
   shl r10, 3;
   imul r10, -1;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetchw [rcx + rax];

           // move:
           movdqa xmm0, [r8 + rax - 128];
           movdqa [rcx + rax - 128], xmm0;

           movdqa xmm1, [r8 + rax - 112];
           movdqa [rcx + rax - 112], xmm1;

           movdqa xmm2, [r8 + rax - 96];
           movdqa [rcx + rax - 96], xmm2;

           movdqa xmm3, [r8 + rax - 80];
           movdqa [rcx + rax - 80], xmm3;

           movdqa xmm0, [r8 + rax - 64];
           movdqa [rcx + rax - 64], xmm0;

           movdqa xmm1, [r8 + rax - 48];
           movdqa [rcx + rax - 48], xmm1;

           movdqa xmm2, [r8 + rax - 32];
           movdqa [rcx + rax - 32], xmm2;

           movdqa xmm3, [r8 + rax - 16];
           movdqa [rcx + rax - 16], xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movdqa xmm0, [r8 + rax];
           movdqa [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;
end;
{$IFDEF FPC}
end;
{$ENDIF}

procedure ASMMatrixCopyUnAlignedEvenW(Dest : PDouble; const destLineWidth : TASMNativeInt; src : PDouble; const srcLineWidth : TASMNativeInt; Width, Height : TASMNativeInt);
{$IFDEF FPC}
begin
{$ENDIF}
asm
   // note: RCX = dest, RDX = destLineWidth, R8 =src, R9 = src
   //iters := -width*sizeof(double);
   mov r10, width;
   shl r10, 3;
   imul r10, -1;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // move:
           movdqu xmm0, [r8 + rax - 128];
           movdqu [rcx + rax - 128], xmm0;

           movdqu xmm1, [r8 + rax - 112];
           movdqu [rcx + rax - 112], xmm1;

           movdqu xmm2, [r8 + rax - 96];
           movdqu [rcx + rax - 96], xmm2;

           movdqu xmm3, [r8 + rax - 80];
           movdqu [rcx + rax - 80], xmm3;

           movdqu xmm0, [r8 + rax - 64];
           movdqu [rcx + rax - 64], xmm0;

           movdqu xmm1, [r8 + rax - 48];
           movdqu [rcx + rax - 48], xmm1;

           movdqu xmm2, [r8 + rax - 32];
           movdqu [rcx + rax - 32], xmm2;

           movdqu xmm3, [r8 + rax - 16];
           movdqu [rcx + rax - 16], xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movdqu xmm0, [r8 + rax];
           movdqu [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;
end;
{$IFDEF FPC}
end;
{$ENDIF}

procedure ASMMatrixCopyAlignedOddW(Dest : PDouble; const destLineWidth : TASMNativeInt; src : PDouble; const srcLineWidth : TASMNativeInt; Width, Height : TASMNativeInt);
{$IFDEF FPC}
begin
{$ENDIF}
asm
   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth
   //iters := -(width - 1)*sizeof(double);
   mov r10, width;
   dec r10;
   shl r10, 3;
   imul r10, -1;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [r8 + rax];
           // prefetchw [rcx + rax];

           // move:
           movdqa xmm0, [r8 + rax - 128];
           movdqa [rcx + rax - 128], xmm0;

           movdqa xmm1, [r8 + rax - 112];
           movdqa [rcx + rax - 112], xmm1;

           movdqa xmm2, [r8 + rax - 96];
           movdqa [rcx + rax - 96], xmm2;

           movdqa xmm3, [r8 + rax - 80];
           movdqa [rcx + rax - 80], xmm3;

           movdqa xmm0, [r8 + rax - 64];
           movdqa [rcx + rax - 64], xmm0;

           movdqa xmm1, [r8 + rax - 48];
           movdqa [rcx + rax - 48], xmm1;

           movdqa xmm2, [r8 + rax - 32];
           movdqa [rcx + rax - 32], xmm2;

           movdqa xmm3, [r8 + rax - 16];
           movdqa [rcx + rax - 16], xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movdqa xmm0, [r8 + rax];
           movdqa [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last element
       movlpd xmm0, [r8];
       movlpd [rcx], xmm0;

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;
end;
{$IFDEF FPC}
end;
{$ENDIF}

procedure ASMMatrixCopyUnAlignedOddW(Dest : PDouble; const destLineWidth : TASMNativeInt; src : PDouble; const srcLineWidth : TASMNativeInt; Width, Height : TASMNativeInt);
{$IFDEF FPC}
begin
{$ENDIF}
asm
   // note: RCX = dest, RDX = destLineWidth, R8 = src, R9 = srcLineWidth
   //iters := -(width - 1)*sizeof(double);
   mov r10, width;
   dec r10;
   shl r10, 3;
   imul r10, -1;

   // helper registers for the mt1, mt2 and dest pointers
   sub r8, r10;
   sub rcx, r10;

   // for y := 0 to height - 1:
   mov r11, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov rax, r10;
       @addforxloop:
           add rax, 128;
           jg @loopEnd;

           // move:
           movdqu xmm0, [r8 + rax - 128];
           movdqu [rcx + rax - 128], xmm0;

           movdqu xmm1, [r8 + rax - 112];
           movdqu [rcx + rax - 112], xmm1;

           movdqu xmm2, [r8 + rax - 96];
           movdqu [rcx + rax - 96], xmm2;

           movdqu xmm3, [r8 + rax - 80];
           movdqu [rcx + rax - 80], xmm3;

           movdqu xmm0, [r8 + rax - 64];
           movdqu [rcx + rax - 64], xmm0;

           movdqu xmm1, [r8 + rax - 48];
           movdqu [rcx + rax - 48], xmm1;

           movdqu xmm2, [r8 + rax - 32];
           movdqu [rcx + rax - 32], xmm2;

           movdqu xmm3, [r8 + rax - 16];
           movdqu [rcx + rax - 16], xmm3;
       jmp @addforxloop

       @loopEnd:

       sub rax, 128;

       jz @nextLine;

       @addforxloop2:
           movdqu xmm0, [r8 + rax];
           movdqu [rcx + rax], xmm0;
       add rax, 16;
       jnz @addforxloop2;

       @nextLine:

       // special care of the last element
       movlpd xmm0, [r8];
       movlpd [rcx], xmm0;

       // next line:
       add r8, r9;
       add rcx, rdx;

   // loop y end
   dec r11;
   jnz @@addforyloop;
end;
{$IFDEF FPC}
end;
{$ENDIF}

{$ENDIF}

end.
