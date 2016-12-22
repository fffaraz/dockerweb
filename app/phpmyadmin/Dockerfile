FROM fffaraz/web/php7nginx:latest
ADD script_*.sh /
RUN chown root:root /script_*.sh && chmod 540 /script_*.sh && sync && /script_init.sh
