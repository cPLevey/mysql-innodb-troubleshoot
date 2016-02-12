#!/bin/sh
#
# Quick and dirty MySQL InnoDB troubleshooting script.
# David Levey
#
if [ ! -z $(grep 'error-log' /etc/my.cnf) ]; then my_err_log=$(grep 'error-log' /etc/my.cnf |awk -F= '{print $2}'); else my_err_log=/var/lib/mysql/$(hostname).err; fi

# last_log_num=$(tail -n5 $my_err_log |awk '{print $1}' |uniq |grep -o '[0-9]*');
# This is no good. Need to grep for line number contaning 'starting as process' and calculate the difference of that and the end. 

log_total_lines=$(wc -l $my_err_log |awk '{print $1}');
last_log_start=$(grep -n 'starting as process' $my_err_log |tail -n1 |awk -F: '{print $1}');
last_log_verb=$(sed -n "$last_log_start","$log_total_lines"p $my_err_log);

inno_corrupt_entries=$(echo "$last_log_verb" |grep -Po "InnoDB:(.*?)corrupt(.*?)");

if [ ! -z "$inno_corrupt_entries" ]; then echo 'FAIL: InnoDB corruption discovered!'; inno_corrupt=1; else echo 'PASS: No corruption discovered in the last log entry of the MySQL error log.'; fi
if inno_corrupt=1; then 
	inno_err_urls=$(echo "$last_log_verb" |grep -Po "http(.*?).html" |uniq);
	specific_errs=$(echo "$last_log_verb" |egrep ERROR\|Error:);
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
	echo "$last_log_verb";
	echo "====";	

	echo "";
	echo "InnoDB errors of the latest MySQL log entry:";
	echo "====";
	echo "$inno_corrupt_entries";
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