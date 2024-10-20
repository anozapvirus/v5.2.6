#!/bin/bash

# Define cores
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
CYAN="\033[36m"
MAGENTA="\033[35m"
NC="\033[0m" # No Color

# Arquivo de checkpoint
CHECKPOINT_FILE="/tmp/deploy_checkpoint.txt"

# Função para imprimir um banner
function print_banner {
  clear
  echo -e "${CYAN}"
  echo "============================================="
  echo "               ATUALIZAÇÃO YRANDEV           "
  echo "============================================="
  echo "██╗   ██╗    ██████╗      █████╗     ███╗   ██╗    ██████╗     ███████╗    ██╗   ██╗"
  echo "╚██╗ ██╔╝    ██╔══██╗    ██╔══██╗    ████╗  ██║    ██╔══██╗    ██╔════╝    ██║   ██║"
  echo " ╚████╔╝     ██████╔╝    ███████║    ██╔██╗ ██║    ██║  ██║    █████╗      ██║   ██║"
  echo "  ╚██╔╝      ██╔══██╗    ██╔══██║    ██║╚██╗██║    ██║  ██║    ██╔══╝      ╚██╗ ██╔╝"
  echo "   ██║       ██║  ██║    ██║  ██║    ██║ ╚████║    ██████╔╝    ███████╗     ╚████╔╝ "
  echo "   ╚═╝       ╚═╝  ╚═╝    ╚═╝  ╚═╝    ╚═╝  ╚═══╝    ╚═════╝     ╚══════╝      ╚═══╝  "
  echo -e "${NC}"
}


# Função para simular progresso de download
function show_download_progress {
  echo -n "${CYAN}Baixando${NC}"
  for i in {1..10}; do
    sleep 0.2
    echo -n "."
  done
  echo -e " ${GREEN}Concluído!${NC}"
}

# Função para registrar logs e etapas
function log_step {
  local step="$1"
  echo "$step" > "$CHECKPOINT_FILE"
}

# Função para log de erro
function log_error {
  local message="$1"
  echo -e "${RED}Erro: $message${NC}" | tee -a /tmp/deploy_error.log
}

# Função para ler o checkpoint
function read_checkpoint {
  if [ -f "$CHECKPOINT_FILE" ]; then
    cat "$CHECKPOINT_FILE"
  else
    echo "start"
  fi
}

# Função para continuar do checkpoint
function continue_from_checkpoint {
  local last_step=$(read_checkpoint)

  case "$last_step" in
    "start")
      log_step "confirm_backup"
      confirm_backup
      ;&
    "confirm_backup")
      log_step "stop_pm2"
      stop_pm2
      ;&
    "stop_pm2")
      log_step "ask_deploy_path"
      ask_deploy_path
      ;&
    "ask_deploy_path")
      log_step "ask_old_folder"
      ask_old_folder
      ;&
    "ask_old_folder")
      log_step "rename_folder"
      rename_folder
      ;&
    "rename_folder")
      log_step "ask_source_path"
      ask_source_path
      ;&
    "ask_source_path")
      log_step "move_files"
      move_files
      ;&
    "move_files")
      log_step "copy_env_files"
      copy_env_files
      ;&
    "copy_env_files")
      log_step "backend_commands"
      backend_commands
      ;&
    "backend_commands")
      log_step "frontend_commands"
      frontend_commands
      ;&
    "frontend_commands")
      log_step "edit_files"
      edit_files
      ;&
    "edit_files")
      log_step "restart_pm2"
      restart_pm2
      ;&
    "restart_pm2")
      echo -e "${GREEN}✅ Script finalizado.${NC}"
      ;;
    *)
      log_error "Checkpoint inválido"
      exit 1
      ;;
  esac
}

# Confirmação de backup
function confirm_backup {
  print_banner
  echo -e "${YELLOW}🔔 AVISO IMPORTANTE: Antes de prosseguir, faça um backup e snapshot da sua máquina (VPS).${NC}"
  read -p "${CYAN}Deseja continuar? [Y/N]: ${NC}" choice

  if [[ "$choice" != "Y" && "$choice" != "y" ]]; then
    log_error "Backup não confirmado"
    exit 1
  fi
}

# Função para parar PM2
function stop_pm2 {
  print_banner
  echo -e "${MAGENTA}⏳ Parando todas as tarefas do PM2...${NC}"
  sudo su deploy -c "pm2 stop all" || log_error "Erro ao parar o PM2"
}

# Função para perguntar o caminho de deploy
function ask_deploy_path {
  print_banner
  echo -e "${YELLOW}🔍 Digite o caminho do diretório de deploy (ex: /home/deploy):${NC}"
  read deploy_path

  if [ ! -d "$deploy_path" ]; then
    log_error "Caminho $deploy_path não existe"
    exit 1
  fi
}

# Função para perguntar a pasta antiga
function ask_old_folder {
  print_banner
  echo -e "${YELLOW}✏️ Digite o nome da pasta que deseja renomear:${NC}"
  read old_folder_name

  if [ ! -d "$old_folder_name" ]; then
    log_error "A pasta $old_folder_name não existe"
    exit 1
  fi
}

# Função para renomear pasta
function rename_folder {
  print_banner
  new_old_folder_name=$(get_incremented_folder_name "$old_folder_name")
  mv "$old_folder_name" "$new_old_folder_name" || log_error "Erro ao renomear a pasta"
}

# Função para perguntar o caminho de origem
function ask_source_path {
  print_banner
  echo -e "${YELLOW}📂 Digite o caminho do diretório de origem (onde os arquivos da instalação estão):${NC}"
  read source_path

  if [ ! -d "$source_path" ]; then
    log_error "Caminho $source_path não existe"
    exit 1
  fi
}

# Função para mover arquivos
function move_files {
  print_banner
  show_download_progress
  mv "$source_path"/* "$deploy_path/$new_folder_name/" || log_error "Erro ao mover arquivos"
}

# Função para copiar arquivos .env e server.js
function copy_env_files {
  print_banner
  echo -e "${CYAN}📄 Copiando arquivos .env e server.js...${NC}"
  cp "$new_old_folder_name/backend/.env" "$new_folder_name/backend/.env" || log_error "Erro ao copiar .env no backend"
  cp "$new_old_folder_name/frontend/.env" "$new_folder_name/frontend/.env" || log_error "Erro ao copiar .env no frontend"
  cp "$new_old_folder_name/frontend/server.js" "$new_folder_name/frontend/server.js" || log_error "Erro ao copiar server.js"
}

# Função para executar comandos no backend
function backend_commands {
  print_banner
  cd "$deploy_path/$new_folder_name/backend" || log_error "Falha ao acessar o diretório do backend"
  npm install || log_error "Erro ao rodar npm install no backend"
  npm run build || log_error "Erro ao rodar npm run build no backend"
  npx sequelize db:migrate || log_error "Erro ao rodar db:migrate no backend"
}

# Função para executar comandos no frontend
function frontend_commands {
  print_banner
  cd "$deploy_path/$new_folder_name/frontend" || log_error "Falha ao acessar o diretório do frontend"
  npm install || log_error "Erro ao rodar npm install no frontend"
  npm run build || log_error "Erro ao rodar npm run build no frontend"
}

# Função para editar arquivos
function edit_files {
  print_banner
  nano "$deploy_path/$new_folder_name/frontend/package.json"
  nano "$deploy_path/$new_folder_name/frontend/public/index.html"
}

# Função para reiniciar PM2
function restart_pm2 {
  print_banner
  echo -e "${MAGENTA}🔄 Reiniciando o PM2...${NC}"
  if ! pm2 restart all; then
    log_error "Falha ao reiniciar o PM2"
  fi
}

# Executa o script a partir do checkpoint
continue_from_checkpoint
