# Ejercicio 1.1 — Comparativa de las computadoras del equipo

> Cada integrante llena **su propia fila** y la sube en su commit
> (ver `REPARTO_COMMITS.md`). Cómo obtener los datos:
>
> | Sistema | RAM / CPU | GPU | Disco libre | Virtualización |
> |---|---|---|---|---|
> | Linux | `free -h`, `lscpu` | `lspci \| grep -i vga` | `df -h ~` | `egrep -c '(vmx\|svm)' /proc/cpuinfo` (>0) y `ls /dev/kvm` |
> | Windows | Administrador de tareas › Rendimiento | ídem | Explorador | Administrador de tareas › CPU › «Virtualización: Habilitado» |
>
> Requisitos del repositorio MacOS-Docker: **16 GB de RAM**, **50 GB libres**
> con Xcode (recomendado ≥ 100 GB) y CPU con virtualización (KVM).

| Integrante | Boleta | SO | CPU (núcleos/hilos) | RAM | GPU | Disco libre | Virtualización | ¿Tiene Mac? |
|---|---|---|---|---|---|---|---|---|
| Jesús Ángel González Arellano | 2022630690 | Linux (kernel 6.17) | Intel Core i5-6200U 2.3 GHz (2 núcleos / 4 hilos) | 7.6 GB | Intel HD Graphics 520 (integrada) | 32 GB | Sí (VT-x, `/dev/kvm`) | No |
| David Alexis Hernandez Gonzalez | 2024630227 | Windows 11 Pro 25H2 (64 bits) | Intel Core i5-10600KF 4.10 GHz (6 núcleos / 12 hilos) | 16.0 GB | NVIDIA GeForce RTX 3060 (12 GB) | 1.17 TB | Sí, habilitada | No |
| Javier de Jesus Gamez Rosas | 2022630007 | Windows 11 (64 bits) | AMD Ryzen 7 3750H 2.30 GHz (4 núcleos / 8 hilos) | 32.0 GB | AMD Radeon RX 5500M (4 GB) + Vega 10 integrada (2 GB) | 66 GB libres de 477 GB (SSD NVMe) | Sí, habilitada | No |
| Amigo de Alexis | «BOLETA_4» | «SO» | «CPU» | «RAM» | «GPU» | «DISCO» | «sí/no» | «sí/no» |

## Equipo seleccionado

- **Responsable del entorno:** David Alexis Hernandez Gonzalez — boleta 2024630227
- **Especificaciones:** Windows 11 Pro 25H2 (64 bits), Intel Core i5-10600KF (6 núcleos / 12 hilos), 16.0 GB de RAM, NVIDIA GeForce RTX 3060 (12 GB) y 1.17 TB libres.
- **Justificación:** La PC asignada cumple los requisitos de MacOS-Docker: 16 GB de RAM, virtualización habilitada y espacio libre suficiente para macOS, Xcode y los simuladores de iOS.
- **Descartados:** la PC de Jesús tiene 7.6 GB de RAM y 32 GB libres, por debajo del mínimo de 16 GB / 50 GB. Pendiente completar los datos de las demás PCs del equipo.
- **Mac física en el equipo:** Ninguno.
- **Aviso al docente** (solo si ninguna PC cumple): No aplica: la PC seleccionada cumple los requisitos mínimos.

## Evidencia

**Especificaciones de la PC elegida**

![Especificaciones](img/01-specs-pc-elegida.png)
