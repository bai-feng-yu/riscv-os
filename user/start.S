.section .text
.global _start
_start:
    call main

spin:
    j spin