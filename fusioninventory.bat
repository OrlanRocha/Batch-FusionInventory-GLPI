@echo off
REM BATCH PARA INSTALAÇAO DO FusionInventory
REM FEITO POR ORLAN ROCHA
REM GITHUB = https://github.com/Luis-Orlan

set versao=2.6
set ip_server=127.0.0.1
set caminhoGLPI=glpi/plugins/fusioninventory
set tarefas=Full

set setup_Options=/S /acceptlicense /runnow /installtasks=%tarefas% /httpd-trust='127.0.0.1/32,%ip_server%' /scan-homedirs /scan-profiles /server='http://%ip_server%/%caminhoGLPI%/'

echo FusionInventory-Agent: Iniciando
echo FusionInventory-Agent: Hostname %computername%

REM DESABILITA Windows FIREWALL (OPCIONAL)
echo FusionInventory-Agent: Ajustando Windows Firewall 
netsh advfirewall set allprofiles state off>nul
netsh advfirewall set domainprofile state off>nul
netsh advfirewall set privateprofile state off>nul
netsh advfirewall set publicprofile state off>nul

echo FusionInventory-Agent: Ajustando servico RDP>nul

REM HABILITA A NO COMPUTADOR (OPCIONAL)
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes>nul
sc config RemoteRegistry start=auto>nul
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f>nul
net stop remoteregistry>nul
net start remoteregistry>nul

REM VALIDA SE O SERVIÇO ESTA RODANDO
net start | find /C /I "FusionInventory Agent">nul
if not %errorlevel%==0 ( 
	echo FusionInventory-Agent: Servico nao esta rodando 
	set instalar=sim
)else (
	echo FusionInventory-Agent: Servico esta rodando
	set instalar=nao
)

REM VALIDAD ARQUITETURA DO SISTEMA
wmic computersystem get systemtype | find /C /I "x64">nul
if not %errorlevel%==0 ( 
	echo FusionInventory-Agent: Sistema Operacional x86
	set arq_system=x86
)else (
	echo FusionInventory-Agent: Sistema Operacional x64
	set arq_system=x64
)

REM DEFINE CAMINHO DO AGENTE
set downloadAgente=http://%ip_server%/%caminhoGLPI%/agent/fusioninventory-agent_windows-%arq_system%_%versao%.exe

REM VALIADA SE O AGENTE DEVE SER INSTALADO
if %instalar% == sim (
 	echo FusionInventory-Agent: Sera necessario instalar o FusionInventory %arq_system% neste terminal
 	goto :baixarAgente
 )else (
 	echo FusionInventory-Agent: O FusionInventory %arq_system% ja esta intalado neste terminal 
 	goto :sair
 )

:baixarAgente
echo FusionInventory-Agent: Servidor %ip_server%

REM DESINSTALA O AGENTE CASO EXISTA 
if exist %ProgramFiles%\FusionInventory-Agent (
	cd %ProgramFiles%\FusionInventory-Agent
	call Uninstall.exe /S ?_=%ProgramFiles%\FusionInventory-Agent\Uninstall.exe
)

if exist %ProgramFiles(x86)%\FusionInventory-Agent (
	cd %ProgramFiles(x86)%\FusionInventory-Agent
	call Uninstall.exe /S ?_=%ProgramFiles(x86)%\FusionInventory-Agent\Uninstall.exe
)

REM FAZ O DOWNLOAD DO AGENTE
echo FusionInventory-Agent: Efetuando download do agente
bitsadmin /RESET /ALLUSERS
bitsadmin /transfer FusionInventory /download /priority normal %downloadAgente% %ProgramData%\fusioninventory-agent_windows-%arq_system%_%versao%.exe

cd C:\ProgramData\

REM FAZ A INSTALAÇÃO DO AGENTE
call fusioninventory-agent_windows-%arq_system%_%versao%.exe %setup_Options%

echo FusionInventory-Agent: Aguardo de 30 segundos para conclusao da instalacao

REM INICIA SERVIÇO CASO NAO INICIOU E FORÇA O INVENTARIO

REM DEFINE SERVIÇO DO AGENTE DE INVENTARIO
sc config FusionInventory-Agent start=delayed-auto

REM RECUPERAÇÃO REINICIAR SERVIÇO 
sc Failure FusionInventory-Agent actions=restart/60000ms/restart/60000/restart/60000ms// reset=3600000

REM INICIA SERVIÇO DO AGENTE DE INVENTARIO
net start FusionInventory-Agent

curl -s http://localhost:62354/status
curl -s http://localhost:62354/now | find "OK">nul
curl -s http://localhost:62354/status | find "status:"

echo FusionInventory-Agent: FIM
goto :sair

:sair
exit

