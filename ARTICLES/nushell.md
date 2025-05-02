# Mise en pratique de NuShell 

Quelques articles parus dans linux-pratique de Benoît Benedetti sur NuShell m'ont donné envie de voir ce que je pouvais faire de cet outil.

Pour ceux qui ne le savent pas NuShell est un shell écrit en Rust, donc récent et dans l'air du temps (c'est impressionnant le nombre d'outils écrit en Rust actuellement non ?). 
NewShell ne se contente pas d'être un shell pour Linux, MacOs et Windows mais il est aussi orienté "data" :

- Des instructions comme "open" ou "fetch" vous permettent d'ouvrir des fichiers en local ou depuis internet pour les afficher sous forme de tables.
- Les pipelines, les outputs sous forme de tables permettent de manipuler les données structurées en lignes et colonnes.
- Les formats d'échanges comme json permettent à NuShell de communiquer avec de nombreux outils.
- La lecture et l'écriture de fichiers dans des formats usuels (csv, json, odt...) fait de NuShell un outil pivot pour traiter des données.

J'ai mis à l'épreuve NuShell (en fait c'est surtout moi qui suis à l'épreuve de sortir de Python) pour voir si l'outil avec mon niveau débutant me permettait de travailler et d'apporter un peu de valeur à mon environnement de travail.

Réponses dans ces lignes ...

## Exemple d'utilisation de NuShell pour afficher dynamiquement son calendrier

L'université planifie mon travail au travers d'un calendrier au format ical, accessible via une URL au travers de l'application ADE. NuShell est capable de parser un calendrier au format ical. 

L'idée est simple :  c'est d'afficher mon calendrier dans mon CLI via NewShell pour sélectionner des évènements ou les extraire. 

Le résultat à obtenir est le suivant (je le reconnais je triche...) :

```bash
$moncal|where SUMMARY =~ SAE|first 5                                                                                                                                                                                               
╭───┬──────────────────────────────────────────────┬──────────────────────────────────────────────┬───────────────────────────────┬────────────┬───────────────────────────────────────────────────────────────────────────────────────╮
│ # │                   DTSTART                    │                    DTEND                     │            SUMMARY            │  LOCATION  │                                      DESCRIPTION                                      │
├───┼──────────────────────────────────────────────┼──────────────────────────────────────────────┼───────────────────────────────┼────────────┼───────────────────────────────────────────────────────────────────────────────────────┤
│ 0 │ Fri, 18 Nov 2022 13:00:00 +0000 (in 2 weeks) │ Fri, 18 Nov 2022 14:15:00 +0000 (in 2 weeks) │ SAE3D04 Infra. Virtualisée-CM │ B202-CLOUD │   DEVCLOUD DEVCLOUD-APP POUCHOULON   JEAN MARC A valider(Exporté le:04/11/2022 02:28) │
│ 1 │ Fri, 18 Nov 2022 14:30:00 +0000 (in 2 weeks) │ Fri, 18 Nov 2022 15:45:00 +0000 (in 2 weeks) │ SAE3D04 Infra. Virtualisée-TD │ B202-CLOUD │   DEVCLOUD DEVCLOUD-APP A valider POUCHOULON   JEAN MARC(Exporté le:04/11/2022 02:28) │
│ 2 │ Fri, 18 Nov 2022 16:00:00 +0000 (in 2 weeks) │ Fri, 18 Nov 2022 17:15:00 +0000 (in 2 weeks) │ SAE3D04 Infra. Virtualisée-E  │ B202-CLOUD │   DEVCLOUD DEVCLOUD-APP POUCHOULON   JEAN MARC A valider(Exporté le:04/11/2022 02:28) │
│ 3 │ Mon, 05 Dec 2022 07:00:00 +0000 (in 4 weeks) │ Mon, 05 Dec 2022 08:15:00 +0000 (in 4 weeks) │ SAE3D04 Infra. Virtualisée-E  │ B202-CLOUD │   DEVCLOUD DEVCLOUD-APP POUCHOULON   JEAN MARC A valider(Exporté le:04/11/2022 02:28) │
│ 4 │ Mon, 05 Dec 2022 08:30:00 +0000 (in 4 weeks) │ Mon, 05 Dec 2022 09:45:00 +0000 (in 4 weeks) │ SAE3D04 Infra. Virtualisée-E  │ B202-CLOUD │   DEVCLOUD DEVCLOUD-APP POUCHOULON   JEAN MARC A valider(Exporté le:04/11/2022 02:28) │
╰───┴──────────────────────────────────────────────┴──────────────────────────────────────────────┴───────────────────────────────┴────────────┴───────────────────────────────────────────────────────────────────────────────────────╯
```

mon calendrier sera un objet table dont les colonnes sont les suivantes:

```bash

$moncal |columns                                                                                                                                                                                                                    11/06/2022 12:52:35
╭───┬─────────────╮
│ 0 │ DTSTART     │
│ 1 │ DTEND       │
│ 2 │ SUMMARY     │
│ 3 │ LOCATION    │
│ 4 │ DESCRIPTION │
╰───┴─────────────╯
```


## Voyons comment maintenant obtenir cette table: 

Je peux récupérer directement le fichier au format ics sur l'application ADE de l'université via la commande fetch mais NewShell n'arrive pas parser le résultat directement. L'erreur renvoyée n'est pas "parlante". Après de nombreux essais, il s'avère que c'est La présence de multi-lignes dans la description de l'évènement qui est la cause. 
Le script Python suivant permet de générer un fichier au format ics exploitable par NuShell.

```Python
# (installation du module icalendar requise )

from icalendar import Calendar, Event, vCalAddress, vText
from datetime import datetime, date
from pathlib import Path
import os
import pytz


with open('./monics.ics', 'rb') as e:
        print("""BEGIN:VCALENDAR
        METHOD:REQUEST
        PRODID:-//ADE/version 6.0
        VERSION:2.0
        CALSCALE:GREGORIAN""")
        ecal = Calendar.from_ical(e.read())
        for component in ecal.walk():
           if component.name == "VEVENT":
               print('BEGIN:VEVENT')
               print('DTSTAMP:' + component.get("DTSTAMP").to_ical().decode('utf-8'))
               print('DTSTART:' + component.get("DTSTART").to_ical().decode('utf-8'))
               print('DTEND:' + component.get("DTEND").to_ical().decode('utf-8'))
               print('SUMMARY:' + component.get("SUMMARY"))
               print('LOCATION:' + component.get("LOCATION"))
               print('DESCRIPTION:' + component.get("DESCRIPTION").replace('\n',' ').strip())
               print('UID:' + component.get("UID"))
               print('CREATED:'+ component.get("CREATED").to_ical().decode('utf-8'))
               print('LAST-MODIFIED:' + component.get("LAST-MODIFIED").to_ical().decode('utf-8'))
               print('SEQUENCE:' + repr(component.decoded("SEQUENCE")))
               print('END:VEVENT')
        print('END:VCALENDAR')
```

Recommençons :

```shell
let urlcal = 'http://....' # mettre l'url fournie par ADE ici
fetch $urlcal|save monics.ics|python nettoieics_nushell.py|from ics              11/06/2022 01:13:03
╭───┬────────────────┬──────────────────┬────────────────┬────────────────┬────────────────┬────────────────┬────────────────╮
│ # │   properties   │      events      │     alarms     │     to-Dos     │    journals    │   free-busys   │   timezones    │
├───┼────────────────┼──────────────────┼────────────────┼────────────────┼────────────────┼────────────────┼────────────────┤
│ 0 │ [table 4 rows] │ [table 324 rows] │ [list 0 items] │ [list 0 items] │ [list 0 items] │ [list 0 items] │ [list 0 items] │
╰───┴────────────────┴──────────────────┴────────────────┴────────────────┴────────────────┴────────────────┴────────────────╯
```

Cette fois-ci le chargement des données a bien été effectué, c'est la colonne **events** qui nous intéresse.
Déception ! L'instruction "**table --expand**" ne permet pas de voir ce qu'elle contient.

```shell
/home/pouchou/ownCloud/dev/nushell〉fetch $urlcal|save monics.ics|python nettoieics_nushell.py|from ics|get events|table -e
╭───┬─────╮
│ 0 │ ... │
╰───┴─────╯
```

Une sortie au format json nous renseigne un peu mieux :

```bash
fetch $urlcal|save monics.ics|python nettoieics_nushell.py|from ics|select events|to json|jq
```

```json
      {
        "properties": [
          {
            "name": "DTSTAMP",
            "value": "20221106T133839Z",
            "params": null
          },
          {
            "name": "DTSTART",
            "value": "20230417T110000Z",
            "params": null
          },
          {
            "name": "DTEND",
            "value": "20230417T140000Z",
            "params": null
          },
          {
            "name": "SUMMARY",
            "value": "SECSER-TD",
            "params": null
          },
          {
            "name": "LOCATION",
            "value": "B203-CYBER",
            "params": null
          },
          {
            "name": "DESCRIPTION",
            "value": "  LPRO CYBER-TDA A valider POUCHOULON   JEAN MARC (Exporté le:06/11/2022 14:38)",
            "params": null
          },
          {
            "name": "UID",
            "value": "ADE604e4f5556454c4c45414e4e4545323032322d323032332d3130343434362d302d",
            "params": null
          },
          {
            "name": "CREATED",
            "value": "19700101T000000Z",
            "params": null
          },
          {
            "name": "LAST-MODIFIED",
            "value": "20221106T133839Z",
            "params": null
          },
          {
            "name": "SEQUENCE",
            "value": "-2063914577",
            "params": null
          }
        ],
        "alarms": []
      }
```

C'est probablement l'encapsulation dans des "arrays json" qui ne nous permet pas une lecture directe.

On va extraire avec jq les données qui nous intéressent (properties) et les "piper" vers NuShell:

```bash
fetch $urlcal|save monics.ics|python nettoieics_nushell.py|from ics|select events|to json |jq  '.[][]
'|from json
╭───┬─────────────────┬────────────────╮
│ # │   properties    │     alarms     │
├───┼─────────────────┼────────────────┤
│ 0 │ [table 10 rows] │ [list 0 items] │
│ 1 │ [table 10 rows] │ [list 0 items] │
│ 2 │ [table 10 rows] │ [list 0 items] │
│ 3 │ [table 10 rows] │ [list 0 items] │
│ 4 │ [table 10 rows] │ [list 0 items] │
...
│ 319 │ [table 10 rows] │ [list 0 items] │
│ 320 │ [table 10 rows] │ [list 0 items] │
│ 321 │ [table 10 rows] │ [list 0 items] │
│ 322 │ [table 10 rows] │ [list 0 items] │
│ 323 │ [table 10 rows] │ [list 0 items] │
├─────┼─────────────────┼────────────────┤
│   # │   properties    │     alarms     │
╰─────┴─────────────────┴────────────────╯
```
On a maintenant une table avec les **events** de notre calendrier.
L'instruction **flatten** permet de supprimer un "niveau" et de voir les données :

```bash
fetch $urlcal|save monics.ics|python nettoieics_nushell.py|from ics|select events|to json |jq  '.[][]
'|from json|get properties |flatten
...
│ 217 │ DESCRIPTION   │   TDAPP POUCHOULON   JEAN MARC A valider (Exporté le:06/11/2022 14:44)                                 │        │
│ 218 │ UID           │ ADE604e4f5556454c4c45414e4e4545323032322d323032332d34353035312d302d32                                  │        │
│ 219 │ CREATED       │ 19700101T000000Z                                                                                       │        │
│ 220 │ LAST-MODIFIED │ 20221106T134450Z                                                                                       │        │
│ 221 │ SEQUENCE      │ -2063914206                                                                                            │        │
│ 222 │ DTSTAMP       │ 20221106T134450Z                                                                                       │        │
│ 223 │ DTSTART       │ 20230410T110000Z                                                                                       │        │
│ 224 │ DTEND         │ 20230410T140000Z                                                                                       │        │
│ 225 │ SUMMARY       │ SECSER-TD                                                                                              │        │
│ 226 │ LOCATION      │ B203-CYBER                                                                                             │        │
│ 227 │ DESCRIPTION   │   LPRO CYBER-TDA A valider POUCHOULON   JEAN MARC (Exporté le:06/11/2022 14:44)                        │        │
│ 228 │ UID           │ ADE604e4f5556454c4c45414e4e4545323032322d323032332d3130343434362d302d                                  │        │
│ 229 │ CREATED       │ 19700101T000000Z                                                                                       │        │
│ 230 │ LAST-MODIFIED │ 20221106T134450Z                                                                                       │        │
│ 231 │ SEQUENCE      │ -2063914206                                                                                            │        │
│ 232 │ DTSTAMP       │ 20221106T134450Z                                                                                       │        │
│ 233 │ DTSTART       │ 20230417T110000Z                                                                                       │        │
│ 234 │ DTEND         │ 20230417T140000Z                                                                                       │        │
│ 235 │ SUMMARY       │ SECSER-TD                                                                                              │        │
│ 236 │ LOCATION      │ B203-CYBER                                                                                             │        │
│ 237 │ DESCRIPTION   │   LPRO CYBER-TDA A valider POUCHOULON   JEAN MARC (Exporté le:06/11/2022 14:44)                        │        │
│ 238 │ UID           │ ADE604e4f5556454c4c45414e4e4545323032322d323032332d3130343434362d302d                                  │        │
│ 239 │ CREATED       │ 19700101T000000Z                                                                                       │        │
│ 240 │ LAST-MODIFIED │ 20221106T134450Z                                                                                       │        │
│ 241 │ SEQUENCE      │ -2063914206                                                                                            │        │
├─────┼───────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────┼────────┤
│   # │     name      │                                                 value                                                  │ params │
╰─────┴───────────────┴────────────────────────────────────────────────────────────────────────────────────────────────────────┴────────
```
C'est mieux, mais ce n'est toujours pas exploitable.
Avec le "**get properties**" on obtient une sortie de type "**list**". Cette information est obtenue à l'aide de l'instruction **describe** qui se révèle très utile. 

```bash
fetch $urlcal|save monics.ics|python nettoieics_nushell.py|from ics|select events|to json |jq  '.[][]
'|from json|get properties |describe
list<table<name: string, value: string, params: nothing>>
```

Un coup d'oeil à la documentation nous indique la voie à suivre :

```bash
help each                                                                        11/06/2022 02:48:55

Search terms: for, loop, iterate

Usage:
  > each {flags} <block>

Subcommands:
  each while - Run a block on each element of input until a $nothing is found

Flags:
  -h, --help - Display this help message
  -k, --keep-empty - keep empty result cells
  -n, --numbered - iterate with an index

Parameters:
  block <Block(Some([Any]))>: the block to run

Examples:
  Multiplies elements in list
  > [1 2 3] | each { |it| 2 * $it }

  Iterate over each element, keeping only values that succeed
  > [1 2 3] | each { |it| if $it == 2 { echo "found 2!"} }

  Iterate over each element, print the matching value and its index
  > [1 2 3] | each -n { |it| if $it.item == 2 { echo $"found 2 at ($it.index)!"} }

  Iterate over each element, keeping all results
  > [1 2 3] | each --keep-empty { |it| if $it == 2 { echo "found 2!"} }
```

Un post [https://stackoverflow.com/questions/73588877/expand-collapsed-data-in-nushell]
me donne la solution qui demande à recréer les colonnes à partir de la liste avec l'instruction **each**:

```bash
fetch $urlcal|save monics.ics|python nettoieics_nushell.py|from ics|select events|to json |jq  '.[][]
'|from json|get properties |each  {|it| {'DTSTAMP': $it.0.value,'DTSTART': $it.1.value,'DTEND':$it.2.value,'SUMMARY': $it.3.value ,'LOCAT
ION': $it.4.value ,'DESCRIPTION':$it.5.value,'CREATED':$it.6.value,'LAST-MODIFIED':$it.7.value,'SEQUENCE':$it.8.value}}
...
│     │              │              │              │              │             │ 22 14:54)   │ d32         │             │             │
│ 322 │ 20221106T135 │ 20230410T110 │ 20230410T140 │ SECSER-TD    │ B203-CYBER  │   LPRO      │ ADE604e4f55 │ 19700101T00 │ 20221106T13 │
│     │ 432Z         │ 000Z         │ 000Z         │              │             │ CYBER-TDA A │ 56454c4c454 │ 0000Z       │ 5432Z       │
│     │              │              │              │              │             │  valider    │ 14e4e454532 │             │             │
│     │              │              │              │              │             │ POUCHOULON  │ 3032322d323 │             │             │
│     │              │              │              │              │             │   JEAN MARC │ 032332d3130 │             │             │
│     │              │              │              │              │             │  (Exporté   │ 343434362d3 │bash             │             │
│     │              │              │              │              │             │ le:06/11/20 │ 02d         │             │             │
│     │              │              │              │              │             │ 22 14:54)   │             │             │             │
│ 323 │ 20221106T135 │ 20230417T110 │ 20230417T140 │ SECSER-TD    │ B203-CYBER  │   LPRO      │ ADE604e4f55 │ 19700101T00 │ 20221106T13 │
│     │ 432Z         │ 000Z         │ 000Z         │              │             │ CYBER-TDA A │ 56454c4c454 │ 0000Z       │ 5432Z       │
│     │              │              │              │              │             │  valider    │ 14e4e454532 │             │             │
│     │              │              │              │              │             │ POUCHOULON  │ 3032322d323 │             │             │
│     │              │              │              │              │             │   JEAN MARC │ 032332d3130 │             │             │
│     │              │              │              │              │             │  (Exporté   │ 343434362d3 │             │             │
│     │              │              │              │              │             │ le:06/11/20 │ 02d         │             │             │
│     │              │              │              │              │             │ 22 14:54)   │             │             │             │
├─────┼──────────────┼──────────────┼──────────────┼──────────────┼─────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│   # │   DTSTAMP    │   DTSTART    │    DTEND     │   SUMMARY    │  LOCATION   │ DESCRIPTION │   CREATED   │ LAST-MODIFI │  SEQUENCE   │
│     │              │              │              │              │             │             │             │ ED          │             │
╰─────┴──────────────┴──────────────┴──────────────┴──────────────┴─────────────┴─────────────┴─────────────┴─────────────┴─────────────╯
```

Toutes les colonnes ne sont pas intéressantes, la date n'est pas dans un format lisible, le tri doit être fait sur la date de départ de l'évènement. 

On re-travaille donc notre sortie :

- Par un tri avec l'instruction **sort-by** sur la colonne DTSTART.
- Par un "cast" de la date via l'instruction **datetime** (l'heure est UTC, il faut donc décaler via une option -o +1).
- Par une ré-écriture des données de la colonne avec l'instruction **udpate**.
- Par le rejet des colonnes qui ne nous apportent rien ici. C'est l'instruction **reject** qui s'en charge.


```bash
fetch $urlcal|save monics.ics|python nettoieics_nushell.py|from ics|select events|to json |jq  '.[][]
'|from json|get properties|each  {|it| {'DTSTAMP': $it.0.value,'DTSTART': $it.1.value,'DTEND':$it.2.value,'SUMMARY': $it.3.value ,'LOCATI
ON': $it.4.value ,'DESCRIPTION':$it.5.value,'CREATED':$it.6.value,'LAST-MODIFIED':$it.7.value,'SEQUENCE':$it.8.value}}| sort-by DTSTART |
update DTSTAMP {|it| $it.DTSTAMP|into datetime -o +1 |to text} |update DTSTART {|it| $it.DTSTART|into datetime -o +1 |to text}|update DTE
ND {|it| $it.DTEND|into datetime -o +1  |to text}|reject DTSTAMP CREATED LAST-MODIFIED SEQUENCE | where SUMMARY =~ "SAE"
...
│    │                           │                           │                           │                   │ le:06/11/2022 15:17)     │
│ 89 │ Wed, 14 Jun 2023 07:30:00 │ Wed, 14 Jun 2023 08:45:00 │ SAE4D01 DevCloud-TD       │ D019-RT           │   DEVCLOUD DEVCLOUD-APP  │
│    │  +0000 (in 7 months)      │  +0000 (in 7 months)      │                           │                   │ A valider POUCHOULON     │
│    │                           │                           │                           │                   │ JEAN MARC(Exporté        │
│    │                           │                           │                           │                   │ le:06/11/2022 15:17)     │
│ 90 │ Wed, 14 Jun 2023 09:00:00 │ Wed, 14 Jun 2023 10:15:00 │ SAE4D01 DevCloud-TD       │ D019-RT           │   DEVCLOUD DEVCLOUD-APP  │
│    │  +0000 (in 7 months)      │  +0000 (in 7 months)      │                           │                   │ A valider POUCHOULON     │
│    │                           │                           │                           │                   │ JEAN MARC(Exporté        │
│    │                           │                           │                           │                   │ le:06/11/2022 15:17)     │
│ 91 │ Wed, 14 Jun 2023 12:00:00 │ Wed, 14 Jun 2023 14:45:00 │ SAE4D01 DevCloud-TP       │ B207              │   DEVCLOUD DEVCLOUD-APP  │
│    │  +0000 (in 7 months)      │  +0000 (in 7 months)      │                           │                   │ A valider POUCHOULON     │
│    │                           │                           │                           │                   │ JEAN MARC(Exporté        │
│    │                           │                           │                           │                   │ le:06/11/2022 15:17)     │
│ 92 │ Wed, 14 Jun 2023 15:00:00 │ Wed, 14 Jun 2023 16:15:00 │ SAE4D01 DevCloud-TD       │ D019-RT           │   DEVCLOUD DEVCLOUD-APP  │
│    │  +0000 (in 7 months)      │  +0000 (in 7 months)      │                           │                   │ A valider POUCHOULON     │
│    │                           │                           │                           │                   │ JEAN MARC(Exporté        │
│    │                           │                           │                           │                   │ le:06/11/2022 15:17)     │
│ 93 │ Thu, 15 Jun 2023 06:00:00 │ Thu, 15 Jun 2023 07:15:00 │ SAE4D01 DevCloud-TD       │ D019-RT           │   DEVCLOUD DEVCLOUD-APP  │
│    │  +0000 (in 7 months)      │  +0000 (in 7 months)      │                           │                   │ A valider POUCHOULON     │
│    │                           │                           │                           │                   │ JEAN MARC(Exporté        │
│    │                           │                           │                           │                   │ le:06/11/2022 15:17)     │
│ 94 │ Thu, 15 Jun 2023 07:30:00 │ Thu, 15 Jun 2023 08:45:00 │ SAE4D01 DevCloud-TD       │ D019-RT           │   DEVCLOUD DEVCLOUD-APP  │
│    │  +0000 (in 7 months)      │  +0000 (in 7 months)      │                           │                   │ A valider POUCHOULON     │
│    │                           │                           │                           │                   │ JEAN MARC(Exporté        │
│    │                           │                           │                           │                   │ le:06/11/2022 15:17)     │
│ 95 │ Thu, 15 Jun 2023 09:00:00 │ Thu, 15 Jun 2023 10:15:00 │ SAE4D01 DevCloud-TD       │ D019-RT           │   DEVCLOUD DEVCLOUD-APP  │
│    │  +0000 (in 7 months)      │  +0000 (in 7 months)      │                           │                   │ A valider POUCHOULON     │
│    │                           │                           │                           │                   │ JEAN MARC(Exporté        │
│    │                           │                           │                           │                   │ le:06/11/2022 15:17)     │
├────┼───────────────────────────┼───────────────────────────┼───────────────────────────┼───────────────────┼──────────────────────────┤
│  # │          DTSTART          │           DTEND           │          SUMMARY          │     LOCATION      │       DESCRIPTION        │
╰────┴───────────────────────────┴───────────────────────────┴───────────────────────────┴───────────────────┴──────────────────────────╯
```

On y est !
Le mode "one liner" c'est bien, mais créer un script NuShell est sûrement judicieux :

```bash
#!/usr/bin/env nu
let urlcal = 'https://proseconsult.umontpellier.fr/jsp/custom/modules/plannings/direct_cal.jsp?data=fdce....'

let moncal = (fetch $urlcal|save monics.ics|python nettoieics_nushell.py|from ics|select events|to json |jq  '.[][]'|from json|get proper
ties|
each  {|it| {'DTSTAMP': $it.0.value,'DTSTART': $it.1.value,'DTEND':$it.2.value,'SUMMARY': $it.3.value ,'LOCATION': $it.4.value ,'DESCRIPT
ION':$it.5.value,'CREATED':$it.6.value,'LAST-MODIFIED':$it.7.value,'SEQUENCE':$it.8.value}}| sort-by DTSTART |
update DTSTAMP {|it| $it.DTSTAMP|into datetime -o +1 |to text} |update DTSTART {|it| $it.DTSTART|into datetime -o +1 |to text}|update DTE
ND {|it| $it.DTEND|into datetime -o +1  |to text}|reject DTSTAMP CREATED LAST-MODIFIED SEQUENCE)
print $moncal
print $moncal|where SUMMARY =~ SAE|first 5
```

Il suffit de lancer le script de cette façon:

```bash
# source permet de récupérer la variable moncal dans le shell actif
source calendar.nu 
/home/pouchou/ownCloud/dev/nushell〉$moncal|where SUMMARY =~ SAE|first 5                                             11/06/2022 03:21:29
╭───┬─────────────────────────────┬─────────────────────────────┬─────────────────────────────┬────────────┬────────────────────────────╮
│ # │           DTSTART           │            DTEND            │           SUMMARY           │  LOCATION  │        DESCRIPTION         │
├───┼─────────────────────────────┼─────────────────────────────┼─────────────────────────────┼────────────┼────────────────────────────┤
│ 0 │ Fri, 18 Nov 2022 13:00:00   │ Fri, 18 Nov 2022 14:15:00   │ SAE3D04 Infra.              │ B202-CLOUD │   DEVCLOUD DEVCLOUD-APP    │
│   │ +0000 (in 2 weeks)          │ +0000 (in 2 weeks)          │ Virtualisée-CM              │            │ POUCHOULON   JEAN MARC A   │
│   │                             │                             │                             │            │ valider(Exporté            │
│   │                             │                             │                             │            │ le:06/11/2022 15:21)       │
│ 1 │ Fri, 18 Nov 2022 14:30:00   │ Fri, 18 Nov 2022 15:45:00   │ SAE3D04 Infra.              │ B202-CLOUD │   DEVCLOUD DEVCLOUD-APP A  │
│   │ +0000 (in 2 weeks)          │ +0000 (in 2 weeks)          │ Virtualisée-TD              │            │ valider POUCHOULON   JEAN  │
│   │                             │                             │                             │            │ MARC(Exporté le:06/11/2022 │
│   │                             │                             │                             │            │  15:21)                    │
│ 2 │ Fri, 18 Nov 2022 16:00:00   │ Fri, 18 Nov 2022 17:15:00   │ SAE3D04 Infra.              │ B202-CLOUD │   DEVCLOUD DEVCLOUD-APP    │
│   │ +0000 (in 2 weeks)          │ +0000 (in 2 weeks)          │ Virtualisée-E               │            │ POUCHOULON   JEAN MARC A   │
│   │                             │                             │                             │            │ valider(Exporté            │
│   │                             │                             │                             │            │ le:06/11/2022 15:21)       │
│ 3 │ Mon, 05 Dec 2022 07:00:00   │ Mon, 05 Dec 2022 08:15:00   │ SAE3D04 Infra.              │ B202-CLOUD │   DEVCLOUD DEVCLOUD-APP    │
│   │ +0000 (in 4 weeks)          │ +0000 (in 4 weeks)          │ Virtualisée-E               │            │ POUCHOULON   JEAN MARC A   │
│   │                             │                             │                             │            │ valider(Exporté            │
│   │                             │                             │                             │            │ le:06/11/2022 15:21)       │
│ 4 │ Mon, 05 Dec 2022 08:30:00   │ Mon, 05 Dec 2022 09:45:00   │ SAE3D04 Infra.              │ B202-CLOUD │   DEVCLOUD DEVCLOUD-APP    │
│   │ +0000 (in 4 weeks)          │ +0000 (in 4 weeks)          │ Virtualisée-E               │            │ POUCHOULON   JEAN MARC A   │
│   │                             │                             │                             │            │ valider(Exporté            │
│   │                             │                             │                             │            │ le:06/11/2022 15:21)       │
╰───┴─────────────────────────────┴─────────────────────────────┴─────────────────────────────┴────────────┴────────────────────────────╯
/home/pouchou/ownCloud/dev/nu
```

Un export est aisé :

```bash
$moncal|to csv
```

Le format de date n'est pas satisfaisant. Malheureusement je n'ai pas réussi via l'instruction "into timezone -o +2" à obtenir  une date à l'heure.
J'ai modifié le script Python afn d'enlever les informations relatives à la TimeZone:

```Python

from icalendar import Calendar, Event, vCalAddress, vText
from datetime import datetime, date
from pathlib import Path
import sys
import os
import pytz

FICHIER = sys.argv[1]
#FICHIER = 'monics.ics'



with open(FICHIER, 'rb') as e:

        def enleve_tz(champ):
            """ PARAM: calendar  date:heure enlève la TimeZone' """
            print(champ + ':' +  str(component.get(champ).dt.replace(tzinfo=None).timestamp()).split('.')[0])

        print("""BEGIN:VCALENDAR
        METHOD:REQUEST
        PRODID:-//ADE/version 6.0
        VERSION:2.0
        CALSCALE:GREGORIAN""")
        ecal = Calendar.from_ical(e.read())
        for component in ecal.walk():
           if component.name == "VEVENT":
               print('BEGIN:VEVENT')
               enleve_tz('DTSTAMP')
               enleve_tz('DTSTART')
               enleve_tz('DTEND')
               print('SUMMARY:' + component.get("SUMMARY"))
               print('LOCATION:' + component.get("LOCATION"))
               print('DESCRIPTION:' + component.get("DESCRIPTION").replace('\n',' ').strip())
               print('UID:' + component.get("UID"))
               enleve_tz('CREATED')
               enleve_tz('LAST-MODIFIED')
               print('SEQUENCE:' + repr(component.decoded("SEQUENCE")))
               print('END:VEVENT')
        print('END:VCALENDAR')
```

J'ai bien réussi à obtenir la bonne heure à condition de me mettre à UTC + 4 au lieu de UTC +2... un bidouillage infâme convenons-en, mais le résultat est celui attendu.

```dotnetcli
#!/usr/bin/env nu
let urlcal = 'https://proseconsult.umontpellier.fr/jsp/custom/modules/plannings/direct_cal.jsp?data=....'

let fichier = 'monics.ics'
let moncal = (fetch $urlcal|save $fichier |python nettoieics_nushell.py $fichier|save monics2.ics|open monics2.ics|select events|to json |jq  '.[][]'|from json|get properties|each  {|it| {'DTSTAMP': $it.0.value,'DTSTART': $it.1.value,'DTEND':$it.2.value,'SUMMARY': $it.3.value ,'LOCATION': $it.4.value ,'DESCRIPTION':$it.5.value,'CREATED':$it.6.value,'LAST-MODIFIED':$it.7.value,'SEQUENCE':$it.8.value}}| sort-by DTSTART |update DTSTAMP {|it| $it.DTSTAMP|into datetime -o +4|date format 'Le %d/%m/%Y à %H:%M'} |update DTSTART {|it| $it.DTSTART|into datetime -o +4|date format 'Le %d/%m/%Y à %H:%M'}|update DTEND {|it| $it.DTEND|into datetime -o +4|date format 'Le %d/%m/%Y à %H:%M'}|reject DTSTAMP CREATED LAST-MODIFIED SEQUENCE)
#$moncal|where SUMMARY =~ SAE|first 5
$moncal
```
```bash
$moncal |where 'SUMMARY' =~ "202"  |where 'SUMMARY' =~ "TP"                                                                                                                                                                  11/11/2022 12:21:03
╭────┬───────────────────────┬───────────────────────┬─────────────────────────┬────────────┬────────────────────────────────────────────────────────────────────────╮
│  # │        DTSTART        │         DTEND         │         SUMMARY         │  LOCATION  │                              DESCRIPTION                               │
├────┼───────────────────────┼───────────────────────┼─────────────────────────┼────────────┼────────────────────────────────────────────────────────────────────────┤
│  0 │ Le 21/04/2023 à 09:30 │ Le 21/04/2023 à 12:15 │ R202 Admin Système-TPB2 │ C214       │ RT-TPB2 POUCHOULON   JEAN MARC A valider (Exporté le:11/11/2022 00:13) │
│  1 │ Le 21/04/2023 à 15:30 │ Le 21/04/2023 à 18:15 │ R202 Admin Système-TPA2 │ C214       │ RT-TPA2 POUCHOULON   JEAN MARC A valider (Exporté le:11/11/2022 00:13) │
│  2 │ Le 02/05/2023 à 09:30 │ Le 02/05/2023 à 12:15 │ R202 Admin Système-TPA1 │ C213       │ RT-TPA1 POUCHOULON   JEAN MARC A valider (Exporté le:11/11/2022 00:13) │
│  3 │ Le 02/05/2023 à 15:30 │ Le 02/05/2023 à 18:15 │ R202 Admin Système-TPB1 │ C213       │ RT-TPB1 A valider POUCHOULON   JEAN MARC (Exporté le:11/11/2022 00:13) │
│  4 │ Le 09/05/2023 à 08:00 │ Le 09/05/2023 à 10:45 │ R202 Admin Système-TPB2 │ B203-CYBER │ RT-TPB2 POUCHOULON   JEAN MARC A valider (Exporté le:11/11/2022 00:13) │
│  5 │ Le 12/05/2023 à 15:30 │ Le 12/05/2023 à 18:15 │ R202 Admin Système-TPA2 │ C214       │ RT-TPA2 POUCHOULON   JEAN MARC A valider (Exporté le:11/11/2022 00:13) │
│  6 │ Le 26/05/2023 à 09:30 │ Le 26/05/2023 à 12:15 │ R202 Admin Système-TPB2 │ C214       │ RT-TPB2 POUCHOULON   JEAN MARC A valider (Exporté le:11/11/2022 00:13) │
│  7 │ Le 26/05/2023 à 15:30 │ Le 26/05/2023 à 18:15 │ R202 Admin Système-TPA2 │ C214       │ RT-TPA2 POUCHOULON   JEAN MARC A valider (Exporté le:11/11/2022 00:13) │
│  8 │ Le 02/06/2023 à 09:30 │ Le 02/06/2023 à 12:15 │ R202 Admin Système-TPB2 │ C214       │ RT-TPB2 POUCHOULON   JEAN MARC A valider (Exporté le:11/11/2022 00:13) │
│  9 │ Le 02/06/2023 à 15:30 │ Le 02/06/2023 à 18:15 │ R202 Admin Système-TPA2 │ C214       │ RT-TPA2 POUCHOULON   JEAN MARC A valider (Exporté le:11/11/2022 00:13) │
│ 10 │ Le 09/06/2023 à 09:30 │ Le 09/06/2023 à 12:15 │ R202 Admin Système-TPB2 │ C214       │ RT-TPB2 POUCHOULON   JEAN MARC A valider (Exporté le:11/11/2022 00:13) │
│ 11 │ Le 09/06/2023 à 14:00 │ Le 09/06/2023 à 16:45 │ R202 Admin Système-TPA2 │ C214       │ RT-TPA2 POUCHOULON   JEAN MARC A valider (Exporté le:11/11/2022 00:13) │
╰────┴───────────────────────┴───────────────────────┴─────────────────────────┴────────────┴────────────────────────────────────────────────────────────────────────╯
```

Il reste maintenant à calculer le nombre d'heures à partir de DTSTART et de DTEND. On ajoute une nouvelle colonne TEMPS. On somme la colonne des heures avec "math sum" dont la valeur est "castée" via "into duration" en heures.

```bash
let moncal =  (fetch $urlcal|save -f $fichier |python nettoieics_nushell.py $fichier|save -f monics2.ics|open monics2.ics|select events|to json |jq  '.[][]'|from json|get proper
ties|each  {|it| {'DTSTAMP': $it.0.value,'DTSTART': $it.1.value,'DTEND':$it.2.value,'SUMMARY': $it.3.value ,'LOCATION': $it.4.value ,'DESCRIPTION':$it.5.value,'CREATED':$it.6.va
lue,'LAST-MODIFIED':$it.7.value,'SEQUENCE':$it.8.value}}| sort-by DTSTART |insert TEMPS {|it| ($it.DTEND|into datetime) - ($it.DTSTART|into datetime)}|move TEMPS --after DTEND|
update DTSTAMP {|it| $it.DTSTAMP|into datetime -o +4|date format 'Le %d/%m/%Y à %H:%M'} |update DTSTART {|it| $it.DTSTART|into datetime -o +4|date format 'Le %d/%m/%Y à %H:%M'}|
update DTEND {|it| $it.DTEND|into datetime -o +4|date format 'Le %d/%m/%Y à %H:%M'}|reject DTSTAMP CREATED LAST-MODIFIED SEQUENCE )

let all_hours = ($moncal|get TEMPS|math sum|into duration --convert hr)
# heures de présence mais pas de cours
let effective_cal =  ($moncal |where 'SUMMARY' !~ "Soutenances" | where 'SUMMARY' !~ "RENTREE")
# heures d'enseignements
let heures_enseignements = ($effective_cal|get TEMPS|math sum|into duration --convert hr)
let heures_cm = ($effective_cal|where SUMMARY =~ "CM" | get TEMPS|math sum|into duration --convert hr)
let heures_td = ($effective_cal|where SUMMARY =~ "TD" | get TEMPS|math sum|into duration --convert hr)
let heures_tp = ($effective_cal|where SUMMARY =~ "TP" | get TEMPS|math sum|into duration --convert hr)
let heures_sae = ($effective_cal|where SUMMARY =~ "SAE" | get TEMPS|math sum|into duration --convert hr)
let heures_devcloud = ($effective_cal|where DESCRIPTION =~ "DEVCLOUD" |get TEMPS|math sum|into duration --convert hr)
print -n "toutes les heures:" $all_hours
print "  "
print -n "heures enseignements:" $heures_enseignements
print "  "
print -n "heures CM:" $heures_cm
print "  "
print -n "heures TD:" $heures_td
print "  "
print -n "heures TP:" $heures_tp
print "  "
print -n "heures SAE:" $heures_sae
print "  "
print -n "heures devcloud:" $heures_devcloud
```

Le rendu est le suivant (je vous laisse imaginer les heures faites...)

```bash
toutes les heures:xxx hr
heures enseignements:xxx.5000 hr
heures CM:xxx.7500 hr
heures TD:xxx.7500 hr
heures TP:xxx hr
heures SAE:xxx hr
heures devcloud:xxx.5000 hr%
```

Un point pour NuShell et pour moi aussi (Ce ne fût pas si simple !).

On va maintenant voir comment avec NuShell on peut interagir avec les données de notre OS Linux.

## NuShell pour extraire des données systèmes et réseau de mon hôte

NuShell dispose de primitives pour extraire des données de l'OS sous-jacent.
Un exemple utile:  

```
ls ~/Téléchargements/ | where size >  500Mib                                       11/06/2022 03:36:10
╭───┬────────────────────────────────────────────────────────────────────────────────────┬──────┬───────────┬───────────────╮
│ # │                                        name                                        │ type │   size    │   modified    │
├───┼────────────────────────────────────────────────────────────────────────────────────┼──────┼───────────┼───────────────┤
│ 0 │ /home/pouchou/Téléchargements/2022-master-cible-win7-fw_up-1.vmdk                  │ file │   6.9 GiB │ 3 weeks ago   │
│ 1 │ /home/pouchou/Téléchargements/VM_MOOC_SRI-20oct2021.ova                            │ file │   7.0 GiB │ 10 months ago │
│ 2 │ /home/pouchou/Téléchargements/c8000v-universalk9.17.09.01a.ova                     │ file │ 882.3 MiB │ 2 months ago  │
│ 3 │ /home/pouchou/Téléchargements/isrv-universalk9.17.03.02.SPA.bin                    │ file │ 520.4 MiB │ 2 months ago  │
│ 4 │ /home/pouchou/Téléchargements/isrv-universalk9.17.03.03.qcow2                      │ file │   1.4 GiB │ 2 months ago  │
│ 5 │ /home/pouchou/Téléchargements/transfer_3986821_files_d51280f1(1).86ceFGZt.zip.part │ file │   2.2 GiB │ 3 weeks ago   │
╰───┴────────────────────────────────────────────────────────────────────────────────────┴──────┴───────────┴───────────────╯
```

Mais NuShell est jeune et toutes les commandes d'un shell comme bash ne peuvent pas être ré-écrites...
Il est donc intéressant de "nourrir" NuShell avec des données issues d'applications capables d'exporter dans un format d'échange universel comme **json**.

C'est le cas ici avec un autre exemple orienté réseaux (**js** transforme la sortie de commandes **bash** en **json**):

```bash
ss -tunlp|jc --ss|from json|sort-by -n local_port |where ($it.local_port | into decimal) < 1024

╭────┬───────┬────────┬────────┬────────┬─────────────────┬────────────┬──────────────┬─────────────────┬────────────────┬──────────────╮
│  # │ netid │ state  │ recv_q │ send_q │  local_address  │ local_port │ peer_address │ peer_portproces │ local_port_num │  interface   │
│    │       │        │        │        │                 │            │              │ s               │                │              │
├────┼───────┼────────┼────────┼────────┼─────────────────┼────────────┼──────────────┼─────────────────┼────────────────┼──────────────┤
│  0 │ tcp   │ LISTEN │      0 │    128 │ 0.0.0.0         │ 22         │ 0.0.0.0      │ *               │             22 │ ❎           │
│  1 │ tcp   │ LISTEN │      0 │    128 │ [::]            │ 22         │ [::]         │ *               │             22 │ ❎           │
│  2 │ udp   │ UNCONN │      0 │      0 │ 10.0.3.1        │ 53         │ 0.0.0.0      │ *               │             53 │ ❎           │
│  3 │ udp   │ UNCONN │      0 │      0 │ 10.32.208.1     │ 53         │ 0.0.0.0      │ *               │             53 │ ❎           │
│  4 │ udp   │ UNCONN │      0 │      0 │ 192.168.122.1   │ 53         │ 0.0.0.0      │ *               │             53 │ ❎           │
│  5 │ udp   │ UNCONN │      0 │      0 │ 10.130.119.1    │ 53         │ 0.0.0.0      │ *               │             53 │ ❎           │
│  6 │ udp   │ UNCONN │      0 │      0 │ 127.0.0.53      │ 53         │ 0.0.0.0      │ *               │             53 │ lo           │
│  7 │ tcp   │ LISTEN │      0 │     32 │ 10.0.3.1        │ 53         │ 0.0.0.0      │ *               │             53 │ ❎           │
│  8 │ tcp   │ LISTEN │      0 │     32 │ 10.32.208.1     │ 53         │ 0.0.0.0      │ *               │             53 │ ❎           │
│  9 │ tcp   │ LISTEN │      0 │     32 │ 192.168.122.1   │ 53         │ 0.0.0.0      │ *               │             53 │ ❎           │
│ 10 │ tcp   │ LISTEN │      0 │     32 │ 10.130.119.1    │ 53         │ 0.0.0.0      │ *               │             53 │ ❎           │
│ 11 │ tcp   │ LISTEN │      0 │   4096 │ 127.0.0.53      │ 53         │ 0.0.0.0      │ *               │             53 │ lo           │
│ 12 │ udp   │ UNCONN │      0 │      0 │ 0.0.0.0         │ 67         │ 0.0.0.0      │ *               │             67 │ lxcbr0       │
│ 13 │ udp   │ UNCONN │      0 │      0 │ 0.0.0.0         │ 67         │ 0.0.0.0      │ *               │             67 │ mpqemubr0    │
│ 14 │ udp   │ UNCONN │      0 │      0 │ 0.0.0.0         │ 67         │ 0.0.0.0      │ *               │             67 │ virbr0       │
│ 15 │ udp   │ UNCONN │      0 │      0 │ 0.0.0.0         │ 67         │ 0.0.0.0      │ *               │             67 │ internet-wrt │
│ 16 │ udp   │ UNCONN │      0 │      0 │ 0.0.0.0         │ 111        │ 0.0.0.0      │ *               │            111 │ ❎           │
│ 17 │ udp   │ UNCONN │      0 │      0 │ [::]            │ 111        │ [::]         │ *               │            111 │ ❎           │
│ 18 │ tcp   │ LISTEN │      0 │   4096 │ 0.0.0.0         │ 111        │ 0.0.0.0      │ *               │            111 │ ❎           │
│ 19 │ tcp   │ LISTEN │      0 │   4096 │ [::]            │ 111        │ [::]         │ *               │            111 │ ❎           │
│ 20 │ tcp   │ LISTEN │      0 │     50 │ 0.0.0.0         │ 139        │ 0.0.0.0      │ *               │            139 │ ❎           │
│ 21 │ tcp   │ LISTEN │      0 │     50 │ [::]            │ 139        │ [::]         │ *               │            139 │ ❎           │
│ 22 │ tcp   │ LISTEN │      0 │     50 │ 0.0.0.0         │ 445        │ 0.0.0.0      │ *               │            445 │ ❎           │
│ 23 │ tcp   │ LISTEN │      0 │     50 │ [::]            │ 445        │ [::]         │ *               │            445 │ ❎           │
│ 24 │ udp   │ UNCONN │      0 │      0 │ [fe80::17b0:285 │ 546        │ [::]         │ *               │            546 │ wlp2s0       │
│    │       │        │        │        │ d:567b:94f9]    │            │              │                 │                │              │
│ 25 │ udp   │ UNCONN │      0 │      0 │ [fe80::2d5a:b55 │ 546        │ [::]         │ *               │            546 │ enp12s0      │
│    │       │        │        │        │ 6:2748:7a99]    │            │              │                 │                │              │
│ 26 │ udp   │ UNCONN │      0 │      0 │ [::]            │ 547        │ [::]         │ *               │            547 │ internet-wrt │
│ 27 │ udp   │ UNCONN │      0 │      0 │ 0.0.0.0         │ 631        │ 0.0.0.0      │ *               │            631 │ ❎           │
│ 28 │ tcp   │ LISTEN │      0 │    128 │ 127.0.0.1       │ 631        │ 0.0.0.0      │ *               │            631 │ ❎           │
│ 29 │ tcp   │ LISTEN │      0 │    128 │ [::1]           │ 631        │ [::]         │ *               │            631 │ ❎           │
│ 30 │ tcp   │ LISTEN │      0 │      5 │ 0.0.0.0         │ 902        │ 0.0.0.0      │ *               │            902 │ ❎           │
│ 31 │ tcp   │ LISTEN │      0 │      5 │ [::]            │ 902        │ [::]         │ *               │            902 │ ❎           │
├────┼───────┼────────┼────────┼────────┼─────────────────┼────────────┼──────────────┼─────────────────┼────────────────┼──────────────┤
│  # │ netid │ state  │ recv_q │ send_q │  local_address  │ local_port │ peer_address │ peer_portproces │ local_port_num │  interface   │
│    │       │        │        │        │                 │            │              │ s               │                │              │
╰────┴───────┴────────┴────────┴────────┴─────────────────┴────────────┴──────────────┴─────────────────┴────────────────┴──────────────
```


Il existe un logiciel qui fournit des "tonnes" de données systèmes, réseaux et sécurité au format json : c'est **osquery**.
Il faut l'installer mais le jeu en vaut la chandelle (même sans NewShell). Il est lui aussi orienté "tables" mais l'interrogation de ses données est orientée **SQL**.

Regardons si on peut transmettre les données de osquery à NuShell:

```bash
osqueryi "select * FROM users;" --json|from json                                 11/06/2022 03:45:45
╭────┬────────────────────┬────────────────────┬───────┬────────────┬───────────────────┬───────┬────────────┬───────────────────┬──────╮
│  # │    description     │     directory      │  gid  │ gid_signed │       shell       │  uid  │ uid_signed │     username      │ uuid │
├────┼────────────────────┼────────────────────┼───────┼────────────┼───────────────────┼───────┼────────────┼───────────────────┼──────┤
│  0 │ root               │ /root              │ 0     │ 0          │ /bin/zsh          │ 0     │ 0          │ root              │      │
│  1 │ daemon             │ /usr/sbin          │ 1     │ 1          │ /usr/sbin/nologin │ 1     │ 1          │ daemon            │      │
│  2 │ bin                │ /bin               │ 2     │ 2          │ /usr/sbin/nologin │ 2     │ 2          │ bin               │      │
│  3 │ sys                │ /dev               │ 3     │ 3          │ /usr/sbin/nologin │ 3     │ 3          │ sys               │      │
│  4 │ sync               │ /bin               │ 65534 │ 65534      │ /bin/sync         │ 4     │ 4          │ sync              │      │
│  5 │ games              │ /usr/games         │ 60    │ 60         │ /usr/sbin/nologin │ 5     │ 5          │ games             │      │
│  6 │ man                │ /var/cache/man     │ 12    │ 12         │ /usr/sbin/nologin │ 6     │ 6          │ man               │      │
│  7 │ lp                 │ /var/spool/lpd     │ 7     │ 7          │ /usr/sbin/nologin │ 7     │ 7          │ lp                │      │
│  8 │ mail               │ /var/mail          │ 8     │ 8          │ /usr/sbin/nologin │ 8     │ 8          │ mail              │      │
│  9 │ news               │ /var/spool/news    │ 9     │ 9          │ /usr/sbin/nologin │ 9     │ 9          │ news              │      │
│ 10 │ uucp               │ /var/spool/uucp    │ 10    │ 10         │ /usr/sbin/nologin │ 10    │ 10         │ uucp              │      │
│ 11 │ proxy              │ /bin               │ 13    │ 13         │ /usr/sbin/nologin │ 13    │ 13         │ proxy             │      │
│ 12 │ www-data           │ /var/www           │ 33    │ 33         │ /usr/sbin/nologin │ 33    │ 33         │ www-data          │      │
│ 13 │ backup             │ /var/backups       │ 34    │ 34         │ /usr/sbin/nologin │ 34    │ 34         │ backup            │      │
│ 14 │ Mailing List       │ /var/list          │ 38    │ 38         │ /usr/sbin/nologin │ 38    │ 38         │ list              │      │
│    │ Manager            │                    │       │            │                   │       │            │                   │      │
│ 15 │ ircd               │ /run/ircd          │ 39    │ 39         │ /usr/sbin/nologin │ 39    │ 39         │ irc               │      │
│ 16 │ Gnats              │ /var/lib/gnats     │ 41    │ 41         │ /usr/sbin/nologin │ 41    │ 41         │ gnats             │      │
│    │ Bug-Reporting      │                    │       │            │                   │       │            │                   │      │
│    │ System (admin)     │                    │       │            │                   │       │            │                   │      │
│ 17 │ nobody             │ /nonexistent       │ 65534 │ 65534      │ /usr/sbin/nologin │ 65534 │ 65534      │ nobody            │      │
│ 18 │ systemd Network    │ /run/systemd/netif │ 102   │ 102        │ /usr/sbin/nologin │ 100   │ 100        │ systemd-network   │      │
│    │ Management,,,      │                    │       │            │                   │       │            │                   │      │
│ 19 │ systemd            │ /run/systemd/resol │ 103   │ 103        │ /usr/sbin/nologin │ 101   │ 101        │ systemd-resolve   │      │
│    │ Resolver,,,        │ ve                 │       │            │                   │       │            │                   │      │
...
```
Ca fonctionne vite et bien !

Un autre exemple ici avec la table docker_images.
```bash
osqueryi "select * FROM docker_images;" --json|from json|update size_bytes {|it| $it.size_bytes |into
 filesize} |sort-by  size_bytes|get size_bytes |reduce -n {|it, acc| $acc.item + $it.item }
62.9 GiB
```

Le nombre de tables osquery est impressionnant il y a surement des possibilités intéressantes (un jour... je regarderais les "yara rules"...).


### systemd & journalctl permette un export en json

On peut ainsi afficher des informations :

```bash
systemctl list-unit-files --type=service -o json|from json

 ─────┬────────────────────────────────────────────┬─────────────────┬───────────────╮
│   # │                 unit_file                  │      state      │ vendor_preset │
├─────┼────────────────────────────────────────────┼─────────────────┼───────────────┤
│   0 │ accounts-daemon.service                    │ enabled         │ enabled       │
│   1 │ acpid.service                              │ disabled        │ enabled       │
│   2 │ alsa-restore.service                       │ static          │               │
│   3 │ alsa-state.service                         │ static          │               │
│   4 │ alsa-utils.service                         │ masked          │ enabled       │
│   5 │ anacron.service                            │ enabled         │ enabled       │
│   6 │ anydesk.service                            │ disabled        │ enabled       │
│   7 │ apache-htcacheclean.service                │ disabled        │ enabled       │
│   8 │ apache-htcacheclean@.service               │ disabled        │ enabled       │
│   9 │ apache2.service                            │ masked          │ enabled       │
│  10 │ apache2@.service                           │ disabled        │ enabled       │
│  11 │ apparmor.service                           │ disabled        │ enabled       │
```


```bash
journalctl -b -o json |jq '. | select(._COMM=="sensors")'  |jq -s '.'|from json| default 'nosyslog'  SYSLOG_IDENTIFIER | update __MONOTONIC_TIMESTAMP {|it| $it.__MONOTONIC_TIMESTAMP |into datetime -o +4|date format 'Le %d/%m/%Y à %H:%M'} |  default 'nomess' MESSAGE| select  __MONOTONIC_TIMESTAMP  MESSAGE

╭────┬───────────────────────┬────────────────────────────────────────────────────────────╮
│  # │ __MONOTONIC_TIMESTAMP │                          MESSAGE                           │
├────┼───────────────────────┼────────────────────────────────────────────────────────────┤
│  0 │ Le 25/05/1970 à 00:36 │ coretemp-isa-0000                                          │
│  1 │ Le 25/05/1970 à 00:36 │ Adapter: ISA adapter                                       │
│  2 │ Le 25/05/1970 à 00:36 │ Package id 0:  +49.0°C  (high = +100.0°C, crit = +100.0°C) │
│  3 │ Le 25/05/1970 à 00:36 │ Core 0:        +49.0°C  (high = +100.0°C, crit = +100.0°C) │
│  4 │ Le 25/05/1970 à 00:36 │ Core 1:        +45.0°C  (high = +100.0°C, crit = +100.0°C) │
│  5 │ Le 25/05/1970 à 00:36 │ Core 2:        +43.0°C  (high = +100.0°C, crit = +100.0°C) │
│  6 │ Le 25/05/1970 à 00:36 │ Core 3:        +43.0°C  (high = +100.0°C, crit = +100.0°C) │
│  7 │ Le 25/05/1970 à 00:36 │ pch_skylake-virtual-0                                      │
│  8 │ Le 25/05/1970 à 00:36 │ Adapter: Virtual device                                    │

```


## Conclusion : affaire à suivre


Tout n'est pas parfait commme le parsing de json qui est moins tolérant que celui réalisé par **jq**. 
Essayez aussi avec "journalctl -o json| from json" pour vous en convaincre. **jq** le "parse" mais NuShell remonte une erreur. C'est surement la faute de systemctl... mais "jq" s'en accomode.

La remontée des erreurs sur le parsing du fichier ical mériterait d'être précise... 

La documentation est utile et efficace mais il y a peu de "posts" encore sur NuShell et donc il faut chercher parfois longtemps ...   

Les idées portées par **NuShell** sont prometteuses et il manque un **powershell** natif à Linux.  
Je ne sais pas trop si il peut remplacer/suppléer un outil Python comme **pandas** ou  le shell **bash** mais il est adapté à des usages récents mettant en jeu des formats comme json, yaml ou même xml. Je le trouve plutôt intéressant pour un ingénieur "data" mais ce n'est pas un avis étayé. 

Je ne suis pas (encore) prêt à laisser zsh ou Python mais c'est une évolution à suivre comme celle du terminal *Alacritty", du multiplexeur "Zelllij" que j'utilise depuis peu et qui ont été développés en **Rust**.


J'ai crée une "cheatsheet" **NAVI** ici: [https://github.com/pushou/navi-cheats/blob/main/nushell.cheat]. Si **fzf** fonctionne d'office sous NuShell ce n'est pas le cas de NAVI (je suis un grand fan de NAVI).

Les articles de Benoit Benedetti qui m'ont mis le pied à l'étrier:

- "Nushell : développez vos scripts et configurez votre shell Magazine" Linux Pratique Numéro 134 novembre 2022.
- "Travaillez avec vos propres données structurées à l’aide de Nushell" Linux Pratique HS Numéro 55 octobre 2022.
- "Nushell : un shell en Rust qui décape" Linux Pratique Numéro 133 septembre 2022.

mais il faut être abonné pour y accéder...
Le site de NuShell est ici: [https://www.nushell.sh/].




 