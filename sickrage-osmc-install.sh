#!/bin/bash

echo ""
echo "#################################"
echo "## OSMC Perfect-Pi :: Sickrage ##"
echo "#################################"
echo ""

# Instalar GIT
echo "[1] Instalación de Sickrage";
echo "[1.1] Comprobando GIT";
/usr/bin/dpkg -l git > /dev/null 2>&1
HAS_GIT=$?
if [ $HAS_GIT -eq "1" ];
then
	echo "Es necesario instalar GIT"
	echo "Instalando mediante apt-get . . ."
	sudo /usr/bin/apt-get -qq -y install git > /dev/null 2>&1
	GIT_INSTALLED=$?
	if [ $GIT_INSTALLED -eq "1" ];
	then
		echo "No se ha podido instalar GIT. Abortando"
		exit 1
	fi

else
	echo "Se ha detectado GIT instalado"
fi

# Clonando GIT
echo "[1.2] Clonando GIT";
sudo /usr/bin/git clone https://github.com/SickRage/SickRage.git /opt/sickrage > /dev/null
if [ $? -ne "0" ];
then
	echo "La operación no se ha podido realizar. Abortando"
	#exit 1
else
	echo "El repositorio se ha clonado correctamente"
fi

# Asignando propietarios
echo "[1.3] Asignando propietarios";
sudo /bin/chown osmc:osmc /opt/sickrage -R > /dev/null
if [ $? -ne "0" ];
then
	echo "La operación no se ha podido realizar. Abortando"
	exit 1
else
	echo "Propietario asignado correctamente"
fi

# Creando script de inicio
echo "[1.4] Creando script de inicio (sickrage.service)";
sudo bash -c 'cat > /etc/systemd/system/sickrage.service' << EOF
[Unit]
Description=SickRage Daemon
After=network.target auditd.service

[Service]
User=osmc
Group=osmc
Type=forking
PIDFile=/run/sickrage.pid
ExecStart=/usr/bin/python2.7 /opt/sickrage/SickBeard.py -q --daemon --pidfile /run/sickrage.pid --nolaunch --datadir=/opt/sickrage
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

if [ $? -ne "0" ];
then
	echo "La operación no se ha podido realizar. Abortando"
	exit 1
else
	echo "Script creado correctamente"
fi

# Iniciando Sickrage
echo "[1.5] Iniciando Sickrage en el puerto 8081 (puede tardar un rato)";
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl restart sickrage
sudo /bin/systemctl status sickrage
if [ $? -ne "0" ];
then
	echo "La operación no se ha podido realizar. Abortando"
	exit 1
else
	echo "Sickrage iniciado correctamente"
fi

# Sickrage autoboot
echo "[1.6] Activando Sickrage en el arranque";
sudo /bin/systemctl enable sickrage

# Sickrage App OSMC
echo "[1.7] Control del servicio desde OSMC (sickrage-app-osmc)";
echo -e "SickRage\nsickrage.service" | sudo tee /etc/osmc/apps.d/sickrage-app-osmc > /dev/null

# config.ini
echo "[1.8] Configurando Sickrate (config.ini)";
/bin/mkdir /home/osmc/Downloads > /dev/null 2>&1
/bin/cp /opt/sickrage/config.ini /opt/sickrage/config.ini.bak
# General
/bin/sed -i 's/auto_update = 0/auto_update = 1/g' /opt/sickrage/config.ini
/bin/sed -i 's/indexerDefaultLang = en/indexerDefaultLang = es/g' /opt/sickrage/config.ini
/bin/sed -i 's/web_username = ""/web_username = osmc/g' /opt/sickrage/config.ini
/bin/sed -i 's/web_password = ""/web_password = osmc/g' /opt/sickrage/config.ini
/bin/sed -i 's/home_layout = poster/home_layout = banner/g' /opt/sickrage/config.ini
# Habilitar NewPCT
/bin/sed -i "s/newpct = 0/newpct = 1/g" /opt/sickrage/config.ini
/bin/sed -i 's/provider_order = ""/provider_order = newpct horriblesubs skytorrents hounddawgs hdbits abnormal alpharatio scenetime btn filelist rarbg hdspace torrentbytes torrentz elitetorrent speedcd tntvillage xthor shazbat_tv torrentproject immortalseed ncore_cc ilcorsaronero morethantv tvchaosuk hdtorrents_it iptorrents danishbits nyaa torrentday pretome cpasbien sceneaccess tokyotoshokan hdtorrents thepiratebay torrent9 bitcannon nebulance hd4free t411 torrentleech limetorrents norbits gftracker archetorrent/g' /opt/sickrage/config.ini
# Formato de hora
/bin/sed -i 's/time_preset = %I:%M:%S %p/time_preset = %H:%M:%S/g' /opt/sickrage/config.ini
# Conectar con Transmission
/bin/sed -i 's/torrent_method = blackhole/torrent_method = transmission/g' /opt/sickrage/config.ini
/bin/sed -i 's/torrent_host = ""/torrent_host = http:\/\/localhost:9091\//g' /opt/sickrage/config.ini
/bin/sed -i 's/torrent_username = ""/torrent_username = osmc/g' /opt/sickrage/config.ini
/bin/sed -i 's/torrent_password = ""/torrent_password = osmc/g' /opt/sickrage/config.ini
# Conectar con Kodi
/bin/sed -i 's/use_kodi = 0/use_kodi = 1/g' /opt/sickrage/config.ini
/bin/sed -i 's/kodi_host = ""/kodi_host = 127.0.0.1:8080/g' /opt/sickrage/config.ini
/bin/sed -i 's/kodi_username = ""/kodi_username = osmc/g' /opt/sickrage/config.ini
/bin/sed -i 's/kodi_password = ""/kodi_password = osmc/g' /opt/sickrage/config.ini
/bin/sed -i 's/kodi_update_library = 0/kodi_update_library = 1/g' /opt/sickrage/config.ini
# Post processing
/bin/sed -i 's/root_dirs = ""/root_dirs = 0|\/home\/osmc\/TV Shows/g' /opt/sickrage/config.ini
/bin/sed -i 's/process_automatically = 0/process_automatically = 1/g' /opt/sickrage/config.ini
/bin/sed -i 's/process_method = copy/process_method = symlink/g' /opt/sickrage/config.ini
/bin/sed -i 's/tv_download_dir = ""/tv_download_dir = \/home\/osmc\/Downloads/g' /opt/sickrage/config.ini
/bin/sed -i 's/naming_pattern = Season %0S\/%SN - S%0SE%0E - %EN/naming_pattern = Season %0S\/%SN.%0Sx%0E.%EN/g' /opt/sickrage/config.ini
# Subtitulos
/bin/sed -i 's/use_subtitles = 0/use_subtitles = 1/g' /opt/sickrage/config.ini
/bin/sed -i 's/subtitles_languages = ""/subtitles_languages = spa/g' /opt/sickrage/config.ini
/bin/sed -i 's/SUBTITLES_SERVICES_LIST = ""/SUBTITLES_SERVICES_LIST = "addic7ed,legendastv,opensubtitles,podnapisi,shooter,thesubdb,tvsubtitles,itasa,subscenter"/g' /opt/sickrage/config.ini
/bin/sed -i 's/SUBTITLES_SERVICES_ENABLED = ""/SUBTITLES_SERVICES_ENABLED = 0|0|1|0|0|0|0|0|0/g' /opt/sickrage/config.ini
echo "Sickrage configurado. Reiniciando . . ."
sudo /bin/systemctl restart sickrage

echo ""
echo "Sickrage instalado correctamente"
