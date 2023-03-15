## Dispatcheris
1. Pridėti routinimą ir papildomus endpointus
2. Pridėti env apdorojimą. Pvz.: išparsinti query parametrus, apkarpyti url dėl lengvesnio routinimo -> pašalint /api/ prierašą, išparsinti headeriuose ateinant tokeną(jei toks bus) ir t.t.
3. Pridėti autentifikavimą, pradžiai gali būti šiaip tokenai, poto jau rimtesnės JWT ar kitų standartų realizacijos.
4. Pridėti bendrą užklausų validavimą
5. Pridėti skirtingų `Content-Type` palaikymą. Pvz.: jei tekstas grįžta `test/html`, jei json'as tada `application/json` ir t.t.
6. Pridėti HTTP kodų palaikymą ir nustatymą -> 404, 201, 200 ...
7. Pridėti CRUD palaikymą su POST, PUT, GET, DELETE metodais
8. Pridėti endpointų hierarchijos logiką - > `192.168.1.1/api/tėvas/vaikas`
9. Padaryti klasę kurią paveldėtų visi endpointai ir joje būtų bendra logika
10. Pridėti UCI palaikymą
11. Naujoje klasęje apsirašyti paprastą "ORM" modelį kurio pagalba enpointuose būtų galima apsirašyti vertes, kurios iškart tiesiogiai rištųsi prie uci verčių ir galiotų default getteriai, setteriai. Šitas toks didenis uždavinys, tai gal jau nebe scope'e akademijoje.
12. Papildomas validacijos sluoksnis. Pvz. dispatcheris patikrina ar atėjo JSON, o pats endpointas tikrina ar yra reikalingi raktai ir panašiai

## Modules used
- [lua-cjson](https://github.com/openwrt/packages/tree/master/lang/lua-cjson "lua-cjson")
- [luasql-sqlite3](https://github.com/openwrt/packages/tree/master/lang/luasql "luasql-sqlite3")
- [luaossl](https://github.com/openwrt/packages/tree/master/lang/luaossl "luaossl")
- [lbase64](https://github.com/iskolbin/lbase64 "lbase64")
- [luaunit](https://github.com/bluebird75/luaunit "luaunit") only for unit testing


- [uHTTPd webserver](https://openwrt.org/docs/guide-user/services/webserver/http.uhttpd "uHTTPd webserver")
- [UCI](https://openwrt.org/docs/techref/uci "UCI")