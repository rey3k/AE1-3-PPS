#!/bin/bash

#declaramos archivos de configuración
USUARIOS_FILE="usuarios.csv"
LOG_FILE="log.log"

#verificamos si el archivo de usuarios existe y lo crea si no
crear_archivo() {
 if [[ ! -f $USUARIOS_FILE ]]; then
  touch "$USUARIOS_FILE"
 fi
}

#registramos los eventos en el log
log_evento() {
 echo "$1 el $(date '+%d/%m/%Y a %H:%M')" >> "$LOG_FILE"
}

#menu principal
menu() {
 echo -e "\nMENU:"
 echo "1. EJECUTAR COPIA DE SEGURIDAD"
 echo "2. DAR DE ALTA USUARIO"
 echo "3. DAR DE BAJA AL USUARIO"
 echo "4. MOSTRAR USUARIOS"
 echo "5. MOSTRAR LOG DEL SISTEMA"
 echo "6. SALIR"
}

#generamos el nombre de usuario 
generauser() {
 local nombre="$1"
 local apellido1="$2"
 local apellido2="$3"
 local dni="$4"
 echo "${nombre:0:1}${apellido1:0:3}${apellido2:0:3}${dni: -3}" | tr '[:upper:]' '[:lower:]'
}

#comprobamos si el usuario existe
existe() {
 local usuario="$1"
 grep -q ":$usuario$" "$USUARIOS_FILE"
}

#copia de seguridad del archivo de usuarios
copia() {
 local fecha_hora
 fecha_hora=$(date '+%d%m%Y_%H-%M-%S')
 local nombre_copia="copia_usuarios_$fecha_hora.zip"

#crear la copiaformato zip
 zip "$nombre_copia" "$USUARIOS_FILE"
 log_evento "COPIA DE SEGURIDAD: $nombre_copia"

#mantener solo las 2 copias mas recientes
 ls -1t copia_usuarios_*.zip | awk 'NR>2' | xargs -d '\n' rm -f --
}

#nuevo usuario
alta() {
 read -p "Nombre: " nombre
 read -p "Apellido 1: " apellido1
 read -p "Apellido 2: " apellido2
 read -p "DNI (8 dígitos + letra): " dni

#validar formato del DNI
  if ! [[ "$dni" =~ ^[0-9]{8}[A-Za-z]{1}$ ]]; then
    echo "DNI no válido. Debe contener 8 dígitos y una letra."
    return
  fi

#generar nombre de usuario
 local usuario
 usuario=$(generauser "$nombre" "$apellido1" "$apellido2" "$dni")

#verificar si el usuario existe
  if existe "$usuario"; then
    echo "El usuario ya existe."
  else
    echo "$nombre:$apellido1:$apellido2:$dni:$usuario" >> "$USUARIOS_FILE"
    log_evento "INSERTADO $nombre:$apellido1:$apellido2:$dni:$usuario"
    echo "Usuario registrado correctamente."
  fi
}

#baja de usuario existente
baja() {
 read -p "Nombre de usuario a eliminar: " usuario
    
#verificamos si existe
 if ! existe "$usuario"; then
  echo "El usuario no existe."
  return
 fi

#eliminar usuario del archivo
 grep -v ":$usuario$" "$USUARIOS_FILE" > temp && mv temp "$USUARIOS_FILE"
 log_evento "BORRADO $usuario"
 echo "Usuario eliminado correctamente."
}

#mstrar lista de usuarios
mostrar_usuarios() {
  if [[ ! -s $USUARIOS_FILE ]]; then
    echo "No hay usuarios registrados."
    return
  fi

  echo "¿Quieres ver los usuarios ordenados alfabeticamente? (s/n)"
  read respuesta

  if [[ "$respuesta" == "s" || "$respuesta" == "s" ]]; then
    echo "Usuarios registrados (ordenados):"
    sort -t: -k5 "$USUARIOS_FILE" | while IFS=: read -r nombre apellido1 apellido2 dni usuario; do
      echo "$usuario - $nombre $apellido1 $apellido2 - $dni"
    done
  else
    echo "Usuarios registrados:"
    cat "$USUARIOS_FILE" | while IFS=: read -r nombre apellido1 apellido2 dni usuario; do
      echo "$usuario - $nombre $apellido1 $apellido2 - $dni"
    done
  fi
}

#mostrar log de eventos
mostrar_log() {
 if [[ ! -s $LOG_FILE ]]; then
  echo "El archivo de log está vacío."
  return
 fi

 cat "$LOG_FILE"
}

#pantalla de login
login() {
 local intentos=3
 while (( intentos > 0 )); do
  read -sp "Introduce tu nombre de usuario: " usuario
  echo

  if [[ "$usuario" == "admin" ]]; then
   return 0
  fi

  if existe "$usuario"; then
   return 0
  fi

  echo "Usuario no válido."
   (( intentos-- ))
  done

  echo "Demasiados intentos. Salida."
  return 1
}

#funcion main
main() {
 crear_archivo

#comprueba si el archivo de usuarios está vacío
  if [[ ! -s $USUARIOS_FILE ]] && [[ "$1" != "-root" ]]; then
   echo "El archivo de usuarios está vacío. Saliendo."
   exit 1
  fi
#realiza login
  if login; then
   while true; do
    menu
    read -p "Elige una opción: " opcion
     case $opcion in
      1) copia ;;
      2) alta ;;
      3) baja ;;
      4) mostrar_usuarios ;;
      5) mostrar_log ;;
      6) echo "Saliendo." ; break ;;
      *) echo "Opción no válida. Intente de nuevo." ;;
     esac
   done
  else
   exit 1
  fi
}

#ejecutar script
main "$@"

