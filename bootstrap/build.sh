#!/bin/bash
# build.sh - Compilación del Stage 0 de Portul

echo "[*] Ensamblando portulc_v0.asm con NASM..."
nasm -f elf64 portulc_v0.asm -o portulc_v0.o

echo "[*] Enlazando con LD (estático, sin libc)..."
ld -m elf_x86_64 -s -o portulc-v0 portulc_v0.o

echo "[+] ¡Compilación exitosa! Binario generado: ./portulc-v0"
echo "[*] Tamaño del binario: $(ls -lh portulc-v0 | awk '{print $5}')"
# Nota: El flag '-s' de ld elimina la tabla de símbolos, reduciendo el tamaño al mínimo absoluto.
