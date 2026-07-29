.section .text
.global _start

_start:
  movl $5, %eax
  movl $marker_path, %ebx
  movl $577, %ecx
  movl $0644, %edx
  int $0x80
  testl %eax, %eax
  js failed

  movl %eax, %edi
  movl $4, %eax
  movl %edi, %ebx
  movl $marker_text, %ecx
  movl $(marker_text_end - marker_text), %edx
  int $0x80
  cmpl $(marker_text_end - marker_text), %eax
  jne close_and_fail

  movl $6, %eax
  movl %edi, %ebx
  int $0x80

  movl $1, %eax
  xorl %ebx, %ebx
  int $0x80

close_and_fail:
  movl $6, %eax
  movl %edi, %ebx
  int $0x80

failed:
  movl $1, %eax
  movl $1, %ebx
  int $0x80

.section .rodata
marker_path:
  .asciz "/tmp/boxedwine-interpreter-ok.txt"
marker_text:
  .ascii "boxedwine-interpreter-ok\n"
marker_text_end:
