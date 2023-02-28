## Dispatcheris
1. Pridėti routinimą ir papildomus endpointus
2. Pridėti env apdorojimą. Pvz.: išparsinti query parametrus, apkarpyti url dėl lengvesnio routinimo -> pašalint /api/ prierašą, išparsinti headeriuose ateinant tokeną(jei toks bus) ir t.t.
3. Pridėti autentifikavimą, pradžiai gali būti šiaip tokenai, poto jau rimtesnės JWT ar kitų standartų realizacijos.
4. Pridėti bendrą užklausų validavimą
5. Pridėti skirtingų `Content-Type` palaikymą. Pvz.: jei tekstas grįžta `test/html`, jei json'as tada `application/json` ir t.t.
6. Pridėti HTTP kodų palaikymą ir nustatymą -> 404, 201, 200 ...

Pridėti CRUD palaikymą su POST, PUT, GET, DELETE metodais
Pridėti endpointų hierarchijos logiką - > `192.168.1.1/api/tėvas/vaikas`
Padaryti klasę kurią paveldėtų visi endpointai ir joje būtų bendra logika
Pridėti UCI palaikymą
Naujoje klasęje apsirašyti paprastą "ORM" modelį kurio pagalba enpointuose būtų galima apsirašyti vertes, kurios iškart tiesiogiai rištųsi prie uci verčių ir galiotų default getteriai, setteriai. Šitas toks didenis uždavinys, tai gal jau nebe scope'e akademijoje.
Papildomas validacijos sluoksnis. Pvz. dispatcheris patikrina ar atėjo JSON, o pats endpointas tikrina ar yra reikalingi raktai ir panašiai