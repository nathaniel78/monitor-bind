#!/bin/bash

<<comment
### SCRIPT PARA MONITORAMENTO DE LINK
# AUTOR: NATHANIEL F.
# DATA: 24/05/2022
# ATUALIZADO: 29/03/2023
# VERSÃO: 1.3
# DESCRIÇÃO: SCRIPT PARA MONITORAMENTO DE DISPONIBILIDADE DO LINK E AJUSTE DO BIND
---> O script deve ter permissão de execução, todas as vezes que for realizado alguma alteração no arquivo zone deve ser desativado o script
e executado novamente, ajustando as entradas novas, onde começa e termina nomes, tanto do link 01 como 02.
comment
# LIMPAR
clear

# MENSAGENS DE ERROR
ERROR_01='O valor digita não pode ser nulo e conter apenas números'
ERROR_02='Entradas não foram configuradas'
ERROR_03='Arquivo bind não foi encontrado'
ERROR_04='Link de monitoramento inválido'
ERROR_05='Arquivo não foi encontrado ou não está configurado'
ERROR_06='Comando não está configurado ou nulo'

# MENSAGENS
MSG_01='
----------- INICIANDO MONITORAMENTO --------------
\nObs.: Toda as alterações no arquivo bind, o monitorameto precisa
\nser parado, resetado as configurações e fazer nova inserçao
\npara que as alterações possam refletir no monitoramento.
'
MSG_02='Criando diretório'
MSG_03='----------- CONFIGURAÇÕES --------------'
MSG_04='Configurações resetadas'
MSG_05='Gerar um novo serial'
MSG_06='incrementando serial'
MSG_07='Será realizado o backup do arquivo db.ifam.zone original'
MSG_08='Trocando de servidor DNS LINK PRINCIPAL -> LINK ALTERNATIVO'
MSG_09='Trocando de servidor DNS LINK ALTERNATIVO -> LINK PRINCIPAL'
MSG_10='Default -> LINK PRINCIPAL'

# DATA ATUAL
DATA_ATUAL=`date +%Y%m%d`

# DATA PERSONALIZADA
DATA_PERS=`date +%Y%m%d%H%M%S`

# DIRETORIO DO BACKUP
DIRETORIO_BACKUP="/root/backup_zone/db.ifam.zone-$DATA_PERS"

# DIRETORIO DO LOG
DIRETORIO_LOG='/root/log_zone/registro_log' 

# CONTADOR
CONTADOR=0

# TIME
TIME_SLEEP=10

# QUANTIDADE DE PING
QTD_PING=30

# URL PARA MONITORAMENTO
URL="google.com"

# STATUS LINK
STATUS_LINK="UP"

# VALIDAR DIRETÓRIO BACKUP
if [ ! -d /root/backup_zone ]; then
	echo $MSG_02
	mkdir /root/backup_zone
fi

# VALIDAR DIRETÓRIO LOG
if [ ! -d /root/log_zone ]; then
	echo $MSG_02
	mkdir /root/log_zone
fi

# MENU
function menu {
	echo ''
	echo "Escolha uma opção:"
	echo "1 - Executar script"
	echo "2 - Configurar entrada dns"
	echo "3 - Configurar caminho do bind"
	echo "4 - Configurar ip de monitoramento"
	echo "5 - Configurar comando que reinicia bind"
	echo "6 - Mostrar configuracoes cadastradas"
	echo "7 - Mostrar log"
	echo "8 - Mostrar backup"
	echo "9 - Resetar configurações"
	echo "10 - Sair"
	
	# LENDO MENU
	read opcao

	# EXECUTA A OPÇÃO SELECIONADA
	case $opcao in
		1)
			monitoramento
			;;
		2)
			entrada
			;;
		3)
			arq_bind
			;;
		4)
			link_monitor
			;;
		5)
			comando_bind
			;;
		6)
			m_configuracoes
			;;
		7)
			m_log
			;;
		8)
			m_backup
			;;
		9)
			reset_config
			;;
		10)
			echo "Saindo..."
			exit 0
			;;
		*)
			echo "Opção inválida."
			exit 0
			;;
	esac
}

# QUANDO APERTAR CTRL + C
function ctrl_c {
        echo ""
        echo ""
        echo "ATENCAO - Voce pressinou CTRL+C"
        echo ""
        while [ true ] ; do
                echo ""
                read -p 'Voce realmente deseja finalizar este script (s/n):' RCTRLC
                case $RCTRLC in
                        s) 
							exit 
							;;
                        n) 
							break 
							;;
                        *) 
							echo 'Apenas s ou n sao respostas validas' 
							;;
                esac
        done
}

trap ctrl_c SIGINT

# RESETANDO VARIAVEIS
function reset_config {
	clear
	echo $MSG_04
	unset CAMINHO_ARQZONE
	unset LINK_MONITORAMENTO
	unset LI_LINK01
	unset LF_LINK01
	unset LI_LINK02
	unset LF_LINK02
	unset COMANDO
	menu
}

# CONFIGURANDO COMANDO BIND
function comando_bind {
	# COMANDO PARA REINICIAR O BIND
	read -p "Digite o comando para reiniciar o bind, ex., systemctl restart bind ou /etc/bind restart: " COMANDO
	if [[ -z $COMANDO ]]; then
		clear
		echo $ERROR_06
		menu
	else
		clear
		echo "O valor digitado: $COMANDO"
		export COMANDO
		menu
	fi
}

# MOSTRAR CONFIGURAÇÕES SALVAS
function m_configuracoes {
	clear
	echo $MSG_03
	echo '# Entradas'
	echo "Início link 01 cadastrado: $LI_LINK01"
	echo "Fim link 01 cadastrado: $LF_LINK01"
	echo "Início link 02 cadastrado: $LI_LINK02"
	echo "Fim link 02 cadastrado: $LF_LINK02"
	echo ''
	echo '# Ip de monitoramento'
	echo "Ip de monitoramento cadastrado: $LINK_MONITORAMENTO"
	echo ''
	echo '# Caminho do arquivo bind'
	echo "Caminho do arquivo bind cadastrado: $CAMINHO_ARQZONE"
	menu
}

# MOSTRAR LOG
function m_log {
	# VALIDANDO ARQUIVO DE LOG
	if [ ! -f $DIRETORIO_LOG ]; then
		clear
		echo $ERROR_05
		menu
	else
		clear
		cat $DIRETORIO_LOG
		menu
	fi
}

# MOSTRAR BACKUP
function m_backup {
	# VALIDANDO ARQUIVO DE LOG
	if [ ! -d /root/backup_zone ]; then
		clear
		echo $ERROR_05
		menu
	else
		clear
		ls /root/backup_zone
		menu
	fi
}

# CAMINHO DO ARQUIVO BIND
function arq_bind {
	# CAMINHO DO ARQUIVO BIND
	read -p "Digite o caminho do arquivo bind: " CAMINHO_ARQZONE
	if [[ -z $CAMINHO_ARQZONE ]] || [[ -f "$CAMINHO_ARQZONE" ]]; then
		clear
		echo $ERROR_03
		menu
	else
		clear
		echo "O valor digitado: $CAMINHO_ARQZONE"
		export CAMINHO_ARQZONE
		menu
	fi
}

# IP DE MONITORAMENTO
function link_monitor {
	# CONFIGURAÇÃO DO LINK DE MONITORAMENTO
	read -p "Digite o ip para monitoramento, exemplo, 192.168.1.1: " LINK_MONITORAMENTO
	if [[ ! $LINK_MONITORAMENTO =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
		clear
		echo $ERROR_04
		menu
	else
		clear
		echo "O valor digitado: $LINK_MONITORAMENTO"
		export LINK_MONITORAMENTO
		menu
	fi
}

# ENTRADAS DOS DNS NO BIND
function entrada {
	# PEGANDO A LINHA INICIAL ONDE COMEÇA O DNS DO LINK 01
	read -p "Digite o número da linha onde começa o DNS do link 01: " LI_LINK01
	if [[ -z $LI_LINK01 ]] || [[ ! $LI_LINK01 =~ ^[0-9]+$ ]]; then
		clear
		echo $ERROR_01
		menu
	else
		clear
		echo "O valor digitado: $LI_LINK01"
		export LI_LINK01
	fi

	# PEGANDO A LINHA INICIAL ONDE FINALIZA O DNS DO LINK 01
	read -p "Digite o número da linha onde termina o DNS do link 01: " LF_LINK01
	if [[ -z $LF_LINK01 ]] || [[ ! $LF_LINK01 =~ ^[0-9]+$ ]]; then
		clear
		echo $ERROR_01
		menu
	else
		clear
		echo "O valor digitado: $LF_LINK01"
		export LF_LINK01
	fi

	# PEGANDO A LINHA INICIAL ONDE COMEÇA O DNS DO LINK 02
	read -p "Digite o número da linha onde começa o DNS do link 02: " LI_LINK02
	if [[ -z $LI_LINK02 ]] || [[ ! $LI_LINK02 =~ ^[0-9]+$ ]]; then
		clear
		echo $ERROR_01
		menu
	else
		clear
		echo "O valor digitado: $LI_LINK02"
		export LI_LINK02
	fi

	# PEGANDO A LINHA INICIAL ONDE FINALIZA O DNS DO LINK 02
	read -p "Digite o número da linha onde termina o DNS do link 02: " LF_LINK02
	if [[ -z $LF_LINK02 ]] || [[ ! $LF_LINK02 =~ ^[0-9]+$ ]]; then
		clear
		echo $ERROR_01
		menu
	else
		clear
		echo "O valor digitado: $LF_LINK02"
		export LF_LINK02
	fi
	
	#VALIDANDO ENTRADA
	if [[ ! -z $LI_LINK01 ]] && [[ ! -z $LF_LINK01 ]] && [[ ! -z $LI_LINK02 ]] && [[ ! -z $LF_LINK02 ]]; then
		clear
		menu
	fi
}

# MONITORAMENTO
function monitoramento {
	#VALIDANDO ENTRADA
	if [[ -z $LI_LINK01 ]] || [[ -z $LF_LINK01 ]] || [[ -z $LI_LINK02 ]] || [[ -z $LF_LINK02 ]]; then
		clear
		echo $ERROR_02
		entrada
	elif [[ -z $CAMINHO_ARQZONE ]]; then
		clear
		echo $ERROR_03
		arq_bind
	elif [[ -z $LINK_MONITORAMENTO ]]; then
		clear
		echo $ERROR_04
		link_monitor
	elif [[ -z $COMANDO ]]; then
		clear
		echo $ERROR_06
		comando_bind
	fi

	clear
	echo ''
	echo -e $MSG_01
	echo ''

	#----- DB.ZONE DEFAULT ----

	# REMOVE ; NA FAIXA DE IP LINK PRINCIPAL
	sed -i "${LI_LINK01},${LF_LINK01}s/;//g" $CAMINHO_ARQZONE

	# ADICIONA ; NA FAIXA DE IP LINK SECUNDARIO
	sed -i "${LI_LINK02},${LF_LINK02}s/^/;/g" $CAMINHO_ARQZONE

	# CAPTURANDO O SERIAL NO ARQUIVO ZONE
	SERIAL=`sed -n '/Serial/{p;q;}' ${CAMINHO_ARQZONE} | awk '{print $1}'`

	# PEGANDO A DATA INICIAL NO SERIAL
	SERIAL_DATA=`echo $SERIAL | cut -c1-8`

	# VERIFICANDO SERIAL COM DATA ATUAL			
	if [ $DATA_ATUAL -gt $SERIAL_DATA ]; then
		# NOVO SERIAL
		NOVO_SERIAL="${DATA_ATUAL}1"

		echo $MSG_05
		
		# SUBSTITUINDO SERIAL POR NOVO SERIAL
		sed -i "s/$SERIAL/$NOVO_SERIAL/g" $CAMINHO_ARQZONE
		
		# RESTART DO SERVIÇO BIND
		$COMANDO
		
	else
		# PEGANDO DIGITO INICIAL
		DIGITOS=`echo $SERIAL | cut -c9-10`

		# NOVO FINAL SERIAL
		NOVO_FINAL=$(($DIGITOS+1))
		
		# INCREMENTANDO SERIAL
		INCREMENTANDO_SERIAL="${DATA_ATUAL}${NOVO_FINAL}"

		echo $MSG_06
		
		# SUBSTITUINDO SERIAL POR NOVO SERIAL
		sed -i "s/$SERIAL/$INCREMENTANDO_SERIAL/g" $CAMINHO_ARQZONE
		
		# RESTART DO SERVIÇO BIND
		$COMANDO
	fi

	echo $MSG_10
	#---------

	# LOOP PARA MONITORAR PING
	while : ; do
			# CASO O PING NÃO RESPONDA PARA LINK PRINCIPAL, VAI PARA DNS ALTERNATIVO
			if ! ping -c $QTD_PING $LINK_MONITORAMENTO >/dev/null && [ "$STATUS_LINK" = "UP" ]; then
			
				# AVISO
				echo $MSG_08
				
				# ALTERANDO STATUS
				STATUS_LINK="DOWN"
				
				# CONTADOR
				CONTADOR=0
				
				# BACKUP
				echo $MSG_07
				cp $CAMINHO_ARQZONE $DIRETORIO_BACKUP
				
				# REGISTRANDO LOG
				echo "Serviço LINK PRINCIPAL INATIVO => $(date +"%x => %X")" >> $DIRETORIO_LOG

				# ADICIONA ; NA FAIXA DE IP LINK PRINCIPAL
				sed -i "${LI_LINK01},${LF_LINK01}s/^/;/g" $CAMINHO_ARQZONE
				
				# REMOVE ; NA FAIXA DE IP LINK SECUNDARIO
				sed -i "${LI_LINK02},${LF_LINK02}s/;//g" $CAMINHO_ARQZONE

				# DATA ATUAL
				DATA_ATUAL=`date +%Y%m%d`

				# DATA PERSONALIZADA
				DATA_PERS=`date +%Y%m%d%H%M%S`
				
				# CAPTURANDO O SERIAL NO ARQUIVO ZONE
				SERIAL=`sed -n '/Serial/{p;q;}' ${CAMINHO_ARQZONE} | awk '{print $1}'`

				# PEGANDO A DATA INICIAL NO SERIAL
				SERIAL_DATA=`echo $SERIAL | cut -c1-8`
				
				# VERIFICANDO SERIAL COM DATA ATUAL			
				if [ $DATA_ATUAL -gt $SERIAL_DATA ]; then
					# NOVO SERIAL
					NOVO_SERIAL="${DATA_ATUAL}1"

					echo $MSG_05
					
					# SUBSTITUINDO SERIAL POR NOVO SERIAL
					sed -i "s/$SERIAL/$NOVO_SERIAL/g" $CAMINHO_ARQZONE
					
					# RESTART DO SERVIÇO BIND
					$COMANDO
					
				else
					# PEGANDO DIGITO INICIAL
					DIGITOS=`echo $SERIAL | cut -c9-10`

					# NOVO FINAL SERIAL
					NOVO_FINAL=$(($DIGITOS+1))
					
					# INCREMENTANDO SERIAL
					INCREMENTANDO_SERIAL="${DATA_ATUAL}${NOVO_FINAL}"

					echo $MSG_06
					
					# SUBSTITUINDO SERIAL POR NOVO SERIAL
					sed -i "s/$SERIAL/$INCREMENTANDO_SERIAL/g" $CAMINHO_ARQZONE
					
					# RESTART DO SERVIÇO BIND
					$COMANDO
				fi
			
			# CASO O LINK 01 RESPONDA, VOLTA A CONFIGURAÇÃO DNS ORIGINAL
			elif ping -c $QTD_PING $LINK_MONITORAMENTO >/dev/null && [ "$STATUS_LINK" = "DOWN" ]; then
			
				# AVISO
				echo $MSG_09

				# ALTERANDO STATUS
				STATUS_LINK="UP"
				
				# CONTADOR
				CONTADOR=0
				
				# REGISTRANDO LOG
				echo "Serviço LINK PRINCIPAL ATIVO => $(date +"%x => %X")" >> $DIRETORIO_LOG

				# REMOVE ; NA FAIXA DE IP LINK PRINCIPAL
				sed -i "${LI_LINK01},${LF_LINK01}s/;//g" $CAMINHO_ARQZONE
				
				# ADICIONA ; NA FAIXA DE IP LINK SECUNDARIO
				sed -i "${LI_LINK02},${LF_LINK02}s/^/;/g" $CAMINHO_ARQZONE
				
				# DATA ATUAL
				DATA_ATUAL=`date +%Y%m%d`

				# DATA PERSONALIZADA
				DATA_PERS=`date +%Y%m%d%H%M%S`
				
				# CAPTURANDO O SERIAL NO ARQUIVO ZONE
				SERIAL=`sed -n '/Serial/{p;q;}' ${CAMINHO_ARQZONE} | awk '{print $1}'`

				# PEGANDO A DATA INICIAL NO SERIAL
				SERIAL_DATA=`echo $SERIAL | cut -c1-8`
				
				# VERIFICANDO SERIAL COM DATA ATUAL			
				if [ $DATA_ATUAL -gt $SERIAL_DATA ]; then
					# NOVO SERIAL
					NOVO_SERIAL="${DATA_ATUAL}1"

					echo $MSG_05
					
					# SUBSTITUINDO SERIAL POR NOVO SERIAL
					sed -i "s/$SERIAL/$NOVO_SERIAL/g" $CAMINHO_ARQZONE
					
					# RESTART DO SERVIÇO BIND
					$COMANDO
					
				else
					# PEGANDO DIGITO INICIAL
					DIGITOS=`echo $SERIAL | cut -c9-10`

					# NOVO FINAL SERIAL
					NOVO_FINAL=$(($DIGITOS+1))
					
					# INCREMENTANDO SERIAL
					INCREMENTANDO_SERIAL="${DATA_ATUAL}${NOVO_FINAL}"

					echo $MSG_06
					
					# SUBSTITUINDO SERIAL POR NOVO SERIAL
					sed -i "s/$SERIAL/$INCREMENTANDO_SERIAL/g" $CAMINHO_ARQZONE
					
					# RESTART DO SERVIÇO BIND
					$COMANDO
				fi

			else
			
				# INCREMENTANDO CONTADOR
				let CONTADOR=CONTADOR+1
				
				# AVISO
				ping -c 1 $URL|echo "$URL => PING OK: $CONTADOR => $(date +"%x => %X") => $(grep 'PING'| cut -d " " -f3)"
			
			fi

			sleep $TIME_SLEEP
	done
}

#CHAMANDO MENU
menu