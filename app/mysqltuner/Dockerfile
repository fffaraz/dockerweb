FROM alpine:latest
ENTRYPOINT ["perl", "mysqltuner.pl"]
RUN \
	apk --no-cache --update add wget perl mysql-client procps && \
	rm -rf /var/cache/apk/* && \
	wget --no-check-certificate -O mysqltuner.pl http://mysqltuner.pl/ && \
	wget --no-check-certificate -O basic_passwords.txt https://raw.githubusercontent.com/major/MySQLTuner-perl/master/basic_passwords.txt && \
	wget --no-check-certificate -O vulnerabilities.csv https://raw.githubusercontent.com/major/MySQLTuner-perl/master/vulnerabilities.csv
