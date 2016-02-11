#!/bin/sh
#
# Quick and dirty MySQL InnoDB troubleshooting script.
# David Levey
#
if [ ! -z $(grep log /etc/my.cnf) ]; then my_err_log=$(grep log /etc/my.cnf |awk -F= '{print $2}'); else my_err_log=/var/lib/mysql/$(hostname).err; fi
last_log_num=$(tail -n5 $my_err_log |awk '{print $1}' |uniq |grep -o '[0-9]*');
inno_corrupt_entries=$(egrep "$last_log_num"\|InnoDB $my_err_log |grep -Po "InnoDB:(.*?)corrupt(.*?)");
if [ ! -z "$inno_corrupt_entries" ]; then echo 'FAIL: InnoDB corruption discovered!'; inno_corrupt=1; else echo 'PASS: No corruption discovered in the last log entry of the MySQL error log.'; fi
if inno_corrupt=1; then 
	inno_verb_last_log=$(egrep $last_log_num\|InnoDB $my_err_log);
	inno_err_urls=$(echo "$inno_verb_last_log" |grep -Po "http(.*?).html" |uniq);
	specific_errs=$(echo "$inno_verb_last_log" |egrep ERROR\|Error:);
	inno_conf_vars=$(grep -i inno /etc/my.cnf |egrep -v '#\|skip');
	if [ -f /usr/bin/systemctl ]; then mysql_status=$(systemctl status mysql); else mysql_status=$(service mysql status); fi

	echo "";
	echo "MySQLs current status:";
	echo "====";
	echo "$mysql_status";
	echo "====";

	echo "";
	echo "Verbose output of the latest MySQL log entry:";
	echo "====";
	echo "$inno_verb_last_log";
	echo "====";	

	echo "";
	echo "URLs provided in the error entry:";
	echo "====";
	echo "$inno_err_urls";
	echo "====";

	echo "";
	echo "Currently enabled InnoDB variables:";
	echo "====";
	echo "$inno_conf_vars";
	echo "====";
	echo "";
fi