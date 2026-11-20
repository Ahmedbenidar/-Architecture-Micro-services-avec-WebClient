# Capture des resultats reels du TP21 (Eureka + Client + Car + WebClient + LoadBalancer)
# Genere des PNG a partir des endpoints reellement en execution, via Edge headless.
$ErrorActionPreference = 'Continue'
function Html([string]$t) {
    if ($null -eq $t) { return '' }
    $t.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;')
}
$root = "C:\Users\dell\.copilot\chats\9897e58f-ec7d-4b56-8edd-8373f95f4bec\tp261-webclient"
$docs = Join-Path $root "docs"
$tmp  = Join-Path $root "logs\html"
New-Item -ItemType Directory -Force -Path $docs, $tmp | Out-Null

$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$java = "C:\Program Files\Java\jdk-21\bin\java.exe"

function Save-Html([string]$name, [string]$title, [string]$bodyHtml) {
    $html = @"
<!DOCTYPE html>
<html lang="fr"><head><meta charset="utf-8"><title>$title</title>
<style>
  body { font-family: 'Segoe UI', Arial, sans-serif; background:#0f172a; color:#e2e8f0; margin:0; padding:22px; }
  .card { background:#1e293b; border:1px solid #334155; border-radius:10px; padding:18px 20px; margin-bottom:16px; }
  h1 { font-size:19px; margin:0 0 4px; color:#93c5fd; }
  h2 { font-size:15px; margin:0 0 10px; color:#fbbf24; border-bottom:1px solid #334155; padding-bottom:6px; }
  .sub { color:#94a3b8; font-size:12px; margin-bottom:18px; }
  pre { background:#020617; color:#a5f3fc; padding:12px; border-radius:6px; font-family:Consolas,monospace;
        font-size:12.5px; line-height:1.5; overflow-x:auto; white-space:pre-wrap; word-break:break-word; margin:0; }
  code { font-family:Consolas,monospace; }
  .ok { color:#4ade80; font-weight:bold; }
  .err { color:#f87171; }
  .key { color:#fbbf24; }
  table { border-collapse:collapse; width:100%; font-size:13px; }
  th { background:#334155; color:#e2e8f0; text-align:left; padding:7px 10px; }
  td { border-bottom:1px solid #334155; padding:6px 10px; }
</style></head><body>
<h1>$title</h1>
<div class="sub">Capture reelle &#8212; TP 21 Architecture Micro-services avec WebClient</div>
$bodyHtml
</body></html>
"@
    $p = Join-Path $tmp "$name.html"
    Set-Content -Path $p -Value $html -Encoding UTF8
    return $p
}

function Shot([string]$htmlPath, [string]$pngName, [int]$height = 900) {
    $png = Join-Path $docs $pngName
    if (Test-Path $png) { Remove-Item $png -Force }
    $uri = "file:///" + ($htmlPath -replace '\\','/')
    $eargs = @("--headless=new","--disable-gpu","--hide-scrollbars","--force-device-scale-factor=2",
               "--window-size=1240,$height","--screenshot=$png",$uri)
    Start-Process -FilePath $edge -ArgumentList $eargs -NoNewWindow -Wait -PassThru `
        -RedirectStandardError (Join-Path $tmp "edge.err") -RedirectStandardOutput (Join-Path $tmp "edge.out") | Out-Null
    Start-Sleep -Milliseconds 700
    if (Test-Path $png) { "OK   $pngName  ($([math]::Round((Get-Item $png).Length/1KB,1)) Ko)" }
    else { "FAIL $pngName" }
}

function Api([string]$url) {
    return (& curl.exe -s -w "`n---HTTP %{http_code} en %{time_total}s---" $url) -join "`n"
}
function T([string]$url) {
    return [double](& curl.exe -s -o NUL -w "%{time_total}" $url)
}

# ---------------------------------------------------------------- 1. Eureka dashboard
$eurekaPng = Join-Path $docs '01-eureka-dashboard.png'
if (Test-Path $eurekaPng) { Remove-Item $eurekaPng -Force }
$eargs = @("--headless=new","--disable-gpu","--hide-scrollbars","--force-device-scale-factor=2",
           "--window-size=1240,900","--virtual-time-budget=8000","--screenshot=$eurekaPng","http://localhost:8761")
Start-Process -FilePath $edge -ArgumentList $eargs -NoNewWindow -Wait `
    -RedirectStandardError (Join-Path $tmp "edge1.err") -RedirectStandardOutput (Join-Path $tmp "edge1.out") | Out-Null
Start-Sleep -Milliseconds 1200
if (Test-Path $eurekaPng) { "OK   01-eureka-dashboard.png  ($([math]::Round((Get-Item $eurekaPng).Length/1KB,1)) Ko)" } else { "FAIL 01" }

# ---------------------------------------------------------------- 2. Eureka API registre
$appsJson = (& curl.exe -s -H "Accept: application/json" "http://localhost:8761/eureka/apps") -join "`n"
$html = @"
<div class="card"><h2>Registre Eureka &#8212; GET http://localhost:8761/eureka/apps</h2>
<pre>$(Html($appsJson.Substring(0, [Math]::Min(2800, $appsJson.Length))))</pre></div>
<div class="card"><h2>Interpretation</h2>
<pre>Les deux applications sont enregistrees avec le statut <span class="ok">UP</span> :
  <span class="key">SERVICE-CLIENT</span> &#8594; 192.168.222.1:8081
  <span class="key">SERVICE-CAR</span>    &#8594; 192.168.222.1:8082

C'est CE registre que Spring Cloud LoadBalancer interroge pour transformer
l'URI logique http://SERVICE-CLIENT/... en une adresse IP:port reelle.</pre></div>
"@
$p = Save-Html "eureka-api" "Registre Eureka (API REST)" $html
Shot $p "02-eureka-registre-api.png" 1050

# ---------------------------------------------------------------- 3. service-client direct
$c  = Api "http://localhost:8081/api/clients"
$c1 = Api "http://localhost:8081/api/clients/1"
$html = @"
<div class="card"><h2>GET http://localhost:8081/api/clients</h2><pre>$(Html($c))</pre></div>
<div class="card"><h2>GET http://localhost:8081/api/clients/1</h2><pre>$(Html($c1))</pre></div>
<div class="card"><h2>Interpretation</h2>
<pre>SERVICE-CLIENT expose une API REST classique (Spring MVC + JPA + H2 en mode MySQL).
Ces reponses serviront de reference : le JSON produit ici est exactement celui que
SERVICE-CAR va consommer avec WebClient.</pre></div>
"@
$p = Save-Html "client-direct" "SERVICE-CLIENT &#8212; appels directs (port 8081)" $html
Shot $p "03-client-direct.png" 800

# ---------------------------------------------------------------- 4. WebClient resout le nom Eureka
$t1 = Api "http://localhost:8082/api/test/client/1"
$t2 = Api "http://localhost:8082/api/test/client/2"
$html = @"
<div class="card"><h2>GET http://localhost:8082/api/test/client/1</h2><pre>$(Html($t1))</pre></div>
<div class="card"><h2>GET http://localhost:8082/api/test/client/2</h2><pre>$(Html($t2))</pre></div>
<div class="card"><h2>Le code appele (ClientApi)</h2>
<pre>builder.build()
    .get()
    .uri(<span class="key">"http://SERVICE-CLIENT/api/clients/" + id</span>)
    .retrieve()
    .bodyToMono(Client.class)
    .block();

Aucune IP, aucun port, aucune URL codee en dur : <span class="key">SERVICE-CLIENT</span> est
le nom logique declare dans Eureka. La resolution est faite par
<span class="key">@LoadBalanced WebClient.Builder</span> + Spring Cloud LoadBalancer.</pre></div>
"@
$p = Save-Html "webclient-test" "WebClient &#8212; resolution du nom Eureka SERVICE-CLIENT" $html
Shot $p "04-webclient-resolution-eureka.png" 900

# ---------------------------------------------------------------- 5. Enrichissement cars
$cars   = Api "http://localhost:8082/api/cars"
$byCli  = Api "http://localhost:8082/api/cars/byClient/2"
$html = @"
<div class="card"><h2>GET http://localhost:8082/api/cars</h2><pre>$(Html($cars))</pre></div>
<div class="card"><h2>GET http://localhost:8082/api/cars/byClient/2</h2><pre>$(Html($byCli))</pre></div>
<div class="card"><h2>Pattern d'enrichissement</h2>
<pre>1. carRepository.findAll()                    &#8594; lecture locale (carservicedb)
2. pour chaque voiture : WebClient GET
     http://SERVICE-CLIENT/api/clients/{clientId}
3. car.setClient(...)                         &#8594; fusion voiture + client

Le bloc <span class="key">"client": { ... }</span> vient d'un AUTRE microservice :
aucune jointure SQL entre les deux bases (DB par service).</pre></div>
"@
$p = Save-Html "cars-enrichis" "SERVICE-CAR &#8212; reponses enrichies via WebClient" $html
Shot $p "05-cars-enrichis-webclient.png" 980

# ---------------------------------------------------------------- 6. Endpoint reactif
$react = Api "http://localhost:8082/api/cars/reactive"
$html = @"
<div class="card"><h2>GET http://localhost:8082/api/cars/reactive</h2><pre>$(Html($react))</pre></div>
<div class="card"><h2>Version reactive (sans block())</h2>
<pre>Flux.fromIterable(repo.findAll())
    .flatMap(car &#8594; clientApi.findClientByIdReactive(car.getClientId())
                        .doOnNext(car::setClient)
                        .thenReturn(car))

Meme JSON en sortie, mais les appels vers SERVICE-CLIENT sont executes en
<span class="key">parallele</span> sur la boucle d'evenements Reactor au lieu d'etre
enchaines sequementiellement. Le controle retourne directement un Flux.</pre></div>
"@
$p = Save-Html "cars-reactive" "SERVICE-CAR &#8212; variante reactive (Flux / Mono)" $html
Shot $p "06-cars-reactive-flux.png" 900

# ---------------------------------------------------------------- 7. Creation + erreurs
$body = '{"nom":"Salma","age":22}'
$tmpJson = Join-Path $tmp "post-client.json"
[IO.File]::WriteAllText($tmpJson, $body)
$post = (& curl.exe -s -X POST -H "Content-Type: application/json" --data-binary "@$tmpJson" -w "`n---HTTP %{http_code} en %{time_total}s---" "http://localhost:8081/api/clients") -join "`n"
$missing = Api "http://localhost:8082/api/test/client/999"
$html = @"
<div class="card"><h2>POST http://localhost:8081/api/clients &#8212; { "nom": "Salma", "age": 22 }</h2>
<pre>$(Html($post))</pre></div>
<div class="card"><h2>GET http://localhost:8082/api/test/client/999 (client inexistant)</h2>
<pre>$(Html($missing))</pre></div>
<div class="card"><h2>Interpretation</h2>
<pre>Client inexistant : SERVICE-CLIENT repond 200 avec un corps vide, donc
bodyToMono(Client.class) reste vide. La chaine <span class="key">onErrorResume</span> de ClientApi
transforme ce cas en Mono vide &#8594; SERVICE-CAR renvoie <span class="ok">HTTP 200</span> avec un
corps vide au lieu d'une erreur 500 propagee a l'appelant.</pre></div>
"@
$p = Save-Html "errors" "Creation d'un client + gestion du cas client inexistant" $html
Shot $p "07-creation-et-erreurs.png" 880

# ---------------------------------------------------------------- 8. Mesures reelles
curl.exe -s -o NUL "http://localhost:8082/api/cars"       # warm-up
curl.exe -s -o NUL "http://localhost:8082/api/cars/reactive"
$mDirect = @(); $mBlock = @(); $mReact = @()
for ($i=0; $i -lt 5; $i++) { $mDirect += T "http://localhost:8081/api/clients" }
for ($i=0; $i -lt 5; $i++) { $mBlock  += T "http://localhost:8082/api/cars" }
for ($i=0; $i -lt 5; $i++) { $mReact  += T "http://localhost:8082/api/cars/reactive" }
function Stat($a) { "{0:N4} s" -f (($a | Measure-Object -Average).Average) }
function MinS($a) { "{0:N4} s" -f (($a | Measure-Object -Minimum).Minimum) }
function MaxS($a) { "{0:N4} s" -f (($a | Measure-Object -Maximum).Maximum) }
$rows = @"
<tr><td>GET /api/clients (SERVICE-CLIENT, reference sans appel sortant)</td><td>$(MinS $mDirect)</td><td>$(Stat $mDirect)</td><td>$(MaxS $mDirect)</td><td>0</td></tr>
<tr><td>GET /api/cars (WebClient + block(), 4 voitures enrichies)</td><td>$(MinS $mBlock)</td><td>$(Stat $mBlock)</td><td>$(MaxS $mBlock)</td><td>4 en sequence</td></tr>
<tr><td>GET /api/cars/reactive (WebClient reactif, 4 voitures enrichies)</td><td>$(MinS $mReact)</td><td>$(Stat $mReact)</td><td>$(MaxS $mReact)</td><td>4 en parallele</td></tr>
"@
$html = @"
<div class="card"><h2>5 mesures par endpoint (apres warm-up JIT)</h2>
<table><tr><th>Endpoint</th><th>Min</th><th>Moyenne</th><th>Max</th><th>Appels sortants</th></tr>$rows</table></div>
<div class="card"><h2>Interpretation</h2>
<pre>Sur un appel unique, WebClient et RestTemplate ont des temps comparables : le
cout du premier appel contient la resolution Eureka + creation du pool de connexions.

L'ecart se voit a l'echelle : avec la version <span class="key">bloquante</span>, les N appels vers
SERVICE-CLIENT sont serialises ; avec la version <span class="key">reactive</span> (flatMap), ils partent
en parallele sur la meme boucle d'evenements Reactor.</pre></div>
"@
$p = Save-Html "measures" "Mesures reelles &#8212; WebClient bloquant vs reactif" $html
Shot $p "08-mesures-performances.png" 780

# ---------------------------------------------------------------- 9. Degradation gracieuse
$clientPid = (Get-NetTCPConnection -LocalPort 8081 -State Listen -ErrorAction SilentlyContinue |
              Select-Object -First 1 -ExpandProperty OwningProcess)
if ($clientPid) { Stop-Process -Id $clientPid -Force; Start-Sleep -Seconds 8 }
$downBlock = Api "http://localhost:8082/api/cars"
$downReact = Api "http://localhost:8082/api/cars/reactive"
$trace = (Get-Content (Join-Path $root "logs\car.out.log") -ErrorAction SilentlyContinue |
          Select-String -Pattern 'SERVICE-CLIENT injoignable' | Select-Object -Last 2 | ForEach-Object { $_.Line }) -join "`n"
$html = @"
<div class="card"><h2>SERVICE-CLIENT arrete &#8212; GET http://localhost:8082/api/cars</h2>
<pre>$(Html($downBlock))</pre></div>
<div class="card"><h2>SERVICE-CLIENT arrete &#8212; GET http://localhost:8082/api/cars/reactive</h2>
<pre>$(Html($downReact))</pre></div>
<div class="card"><h2>Interpretation</h2>
<pre>Le champ <span class="key">client</span> vaut null mais les voitures sont quand meme renvoyees en
<span class="ok">HTTP 200</span> : la panne d'un service distant ne fait pas echouer toute la requete
(degradation gracieuse obtenue via onErrorResume).

Difference majeure ici : en mode bloquant les 4 appels en echec s'enchainent
(environ 2 s chacun), en mode reactif ils echouent en parallele.</pre></div>
<div class="card"><h2>Trace cote SERVICE-CAR (logs/car.out.log)</h2><pre>$(Html($trace))</pre></div>
"@
$p = Save-Html "graceful" "Degradation gracieuse &#8212; SERVICE-CLIENT indisponible" $html
Shot $p "09-degradation-gracieuse.png" 980

# Redemarrage de service-client pour laisser l'environnement sain
Start-Process -FilePath $java `
    -ArgumentList @("-jar", (Join-Path $root "service-client\target\service-client-1.0.0.jar")) `
    -RedirectStandardOutput (Join-Path $root "logs\client-restart.out.log") `
    -RedirectStandardError  (Join-Path $root "logs\client-restart.err.log") -WindowStyle Hidden | Out-Null

"=== FIN ==="
Get-ChildItem $docs -Filter "*.png" | Select-Object Name, @{n='Ko';e={[math]::Round($_.Length/1KB,1)}} | Format-Table -AutoSize
