# monitor-bind
script para monitorar bind e alternar nomes com faixa de ips diferentes

Em um cenário onde a rede possua dois links com ips diferentes e precisa que o bind alterne os nomes entre ips diferentes. O script monitora um ip especifico da rede principal, quando esse ip para de responder, o script alterna para o link de redundância, comentando a faixa demarcada como o link principal, gera um serial e reinicia o serviço do bind.

Passos:
1 - baixar o script.
2 - dar permissão de execução.
3 - ajustar o arquivo bind.
4 - na execução do script, configurar os ajustes.
5 - deixar executar em segundo plano.

O cabeçalho do arquivo zone, deve estar no padrão yyyymmdds (Y = Ano, m = mês, d = dia, s = serial), ex.:

>------------- exemplo de como deve estar o serial ---------------
$TTL    604800
@       IN      SOA     nyc3.example.com. admin.nyc3.example.com. (
                         202301011      ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
; name servers


No arquivo zone, ele deve ter no mesmo arquivo os ips do link principal e o de redundância, os ips devem ser agrupados, onde sejá possível determinar a linha inicial e final do link principal e do link de redundância. ex.:

--------------- arquivo bind - faixa de ip do link principal ---------------
servidor01		  IN	A	  192.168.1.100 
servidor02			IN	A		192.168.1.101

--------------- arquivod bind - faixa de ip do link de redundância --------------
;servidor01		  IN	A	  10.0.0.100 
;servidor02			IN	A		10.0.0.101 

Quando identificar que o ip de monitoramento não está respondendo, o script comenta a faixa de ip do link principal, descomenta do link de redundância, altera o serial e reinicia o serviço.
