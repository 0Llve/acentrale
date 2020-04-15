
# Scripts de supervision de relais avec DejaVu

```
apt install mysql-server python-mysqldb python-numpy python-pydub python-scipy python-matplotlib python-pyaudio jq ffmpeg

echo "create database dejavu" |mysql
echo "create user 'dejavu'@'localhost' identified by 'dejavupassword'" |mysql
echo "grant all privileges on dejavu.* to 'dejavu'@'localhost'" | mysql 
git clone https://github.com/worldveil/dejavu.git ./dejavu
cd dejavu
python example.py
echo "alter table songs add column created timestamp default CURRENT_TIMESTAMP" | mysql dejavu
# Encrypting MySQL Credentials
mysql_config_editor set --login-path=dejavu --host=localhost --user=dejavu --password
```

