# Glasfaserfuchs

Ein dümmlich simples aber durchaus nützliches Tool 
für Nutzerorientierte FAQs und Ähnliches auf Webseiten bei dem auch der Spaß
nicht zu kurz kommt.

Der Glaserfuchs simuliert auf ziemlich stupide Art und Weise einen
Chat-Bot, der auf bestimmte Wörter in Anfragen reagiert und vielleicht passende
Antworten rauswirft.

Das ganze in einem Mobiltelefon-Chat-Interface.

## Wie baue ich den Fuchs?

In `dist/` liegt aktuell schon was fertig gebautes. Das hört aber wieder auf und die releases
wandern an eine passendere Stelle.

Selber bauen geht so:

    $ yarn install
    $ yarn build
    
Die relevanten Dateien vom Fuchs sind nun in `./dist/`. Man kann den Fuch ausprobieren:

    $ cd demo
    $ cp ../dist/* .
    $ python3 -mhttp.Server
    
Jetzt mit dem Browser auf `http://localhost:8000/beispiel.html` nachsehen.

### Der Fuchs sieht aber verdächtig wie eine Elefant aus!?

Der Glasfaserfuchs basiert auf einer Bring-Your-Own-Fox (BYOF) Philisophie. Der Elefant hällt 
den Platz warm.

Der Elefant ist vom kenney.nl. Super Sache!

Einfach `glafaavatar.png` mit einer rundlichen Avatar-Version des Fuchses, `glasfaserfuchs.png` 
mit einer größeren evtl. sogar Ganz-Körper-Version des Fuchses und `graufuchs.png` mit einer 
Silhouette des gewünschten Fuchses austauschen.

## Wie benutze ich den Fuchs?

(Das stimmt hier nicht so ganz. Wenn mit Parcel 1 gebaut wird, gibt es keine data-urls 
und auch die Bilder müssen passend verfügbar sein)

Zum einbinden in eine Webseite `fuchs.css` und `fuchs.js` laden. Und dann einen Glasfaserfuchs erzeugen:

    <div id="glasfaserfuchs"></div>
    
    <style>@import url(fuchs.css);</style>
    <script src="fuchs.js"></script>
    <sript>
    var fuchs = new Glasfaserfuchs(optionen);
    </script>
    
Der Glasfaserfuchs übernimmt ein Element mit der ID `glasfaserfuchs`. 
Dies kann per Option geändert werden.

## Den Fuchs aufschlauen

Der Fuchs muss mit Infos gefüttert werden. Das geht folgendermaßen:

### Im HTML-Dokument selbst

Diese Variante ist Möglich, aber in den meisten Fällen bestimmt nicht ideal. Der Fuchs nimmt als Option
einen Selektor auf ein Element, dass die Fuchsdaten enthält. (Zum Format der Fuchsdaten siehe unten.)
`src_element` ist der Name dieser Option:


    <div id="glasfaserfuchs"></div>
    
    <script type="text/html" id="fuchsdaten>
    hallo guten tag
    
    ## Wer bist Du, lieber Fuchs?
    --
    ## Das geht Dich aber mal gar nix an.
    
    Im Ernst. Wer will das wissen?
    </script>
    
    <style>@import url(fuchs.css);</style>
    <script src="fuchs.js"></script>
    <sript>
    var fuchs = new Glasfaserfuchs({src_element: "#fuchsdaten"});
    </script>    
    
### Aus einer externen Quelle

Besser ist es in den meisten Fällen bestimmt, die Daten separat abzulegen.
Der Fuchs bekommt dann eine URL zur Textdatei mit den Fuchsdaten. Beschränkungen
bzgl. Same-Origin sind zu beachten. Die Text-Datei sollte also unter 
der gleichen Basis-URL (also gleicher Server etc. pp.) wie der Fuchs selbst abgelegt werden.

Dem Fuchs wird die URL zur Textdatei per `src_url` mitgeteilt:

    <div id="glasfaserfuchs"></div>
        
    <style>@import url(fuchs.css);</style>
    <script src="fuchs.js"></script>
    <sript>
    var fuchs = new Glasfaserfuchs({src_url: "http://www.example.com/fuchdaten.txt"});
    </script>
    
### Das Datenformat

Die Daten für den Glasfaserfuchs sehen wie folgt aus:

 * Eine Zeile mit Trigger-Wörtern, durch Leerzeichen getrennt
 * Der Inhalt für die "Frage" an den Glasfaserfuchs
 * Zwei Bindestriche (`--`) alleine auf einer Zeile (auch keine Leerziechen auf dieser Zeile bitte)
 * Der Inhalt für die "Antwort" vom Glasfaserfuchs
 * Drei Bindestrichte (`---`) alleine auf einer Zeile (wieder keine Leerzeichen)

Bitte UTF-8 verwenden.

Die Inhalte können mit [Markdown](https://de.wikipedia.org/wiki/Markdown) formatiert werden.

Ein Beispiel:

    wetter morgen regenschirm schietwetter regen sonne wolken
    
    Wie wird morgen wohl das Wetter?
    --
    ### Die Wettervorhersage für Morgen
    
    Morgen wird es regnen. Vielleicht aber auch nicht. 
    Und es ziehen Wolken umher, wenn es nicht einen klaren 
    Himmel gibt.
    
    [Zum kompletten Wetterbericht](http://kachelmannwetter.com)
    ---
    baud modem glasfaser alteschule
    
    Wie viel Baud hat eigentlich so ein Glasfasermodem?
    --
    Das ist gar nicht so einfach zu benatworten. 
    Ich weiß nämlich gar nicht, wie im Glasfaserfall der
    Datenstrom im Layer 1 aufgebaut ist.
    
    Alles zur Baud-Rate findest 
    Du in der [Wikipedia](https://de.wikipedia.org/wiki/Baud)
    
Kann der Glasfaserfuchs die Daten nicht verstehen, 
zeigt er einen Fehler an. Mit Hilfe der Fehlermeldung sollte man
dem Problem auf die Spur kommen können.

Wird `src_url` verwendet und es gibt Netz-Probleme beim Laden startet der 
Glasfaserfuchs gar nicht oder dumm. Am besten mal die Log-Console im Browser
kontrollieren.

### Besondere Triggerwörter:

* `_extra`: Hat eine Antwort `_extra` als Triggerwort, wird diese Antwort immer
   zusätzlich zur bereits gegebenen Antwort angezeigt. Das ist hilfreich für Weiterführende Infos.

   Benutzt man die Zeichenkette `$ALLEWÖRTER$` im Text der Antwort, wird
   an der Stelle eine Liste mit allen Wörtern die der Glasfaserfuchs kennt 
   eingebaut. Mansche Menschen stöbern lieber oder wissen keine Stichworte einzugeben.
   
* `hallo`: Anworten mit dem Triggerwort `hallo` werden immer angezeigt, wenn 
  kein Stichwort eingegeben wurde. Also direkt nach dem Start.

  Hier kann man den Nutzer begrüßen und evtl. wichtige Dokumente direkt verlinken.

* `_hinweis`: Wird die Option `hinweis` aktiviert, wird unter jeder Antwort
   ein Knopf eingebaut der einen Hinweis anzeigt. Hier kann Kleingedrucktes
   untergebracht werden. z.B.:
   
       _hinweis
       
       egal. Wird nicht angezeigt.
       --
       ## Bitte beachten:
       
       Alle Angaben sind nur für Füchse.
       ---
   
* `_suffix`:  Was hier bei Frage angegeben ist, wird unter jede Frage gesetzt. 
   Mit der Antwort wird ebenso verfahren.    
  
  

## Weitere Optionen für den Glasfaserfuchs

Dem Glasfaserfuchs kann man noch weitere Optionen mitgeben:

### An einem anderen Element ankern

Mit der Option `node` kann man dem Fuchs einen anderen Fuchsbau zuweisen. Es soll
ein CSS-Selektor angegeben werden. z.B.

    <div class="ersatzbau"></div>
    
    <style>@import url(fuchs.css);</style>
    <script src="fuchs.js"></script>
    <sript>
    var fuchs = new Glasfaserfuchs(
                   {src_url: "http://www.example.com/fuchdaten.txt",
                    node: ".ersatzbau"
                   });
                   
    </script>        

### Einige Zeichenketten überschreiben

Mit der Option `strings` kann man dem Fuchs andere Sprüche auf die Zunge legen:


    <sript>
    var fuchs = new Glasfaserfuchs(
                   {src_url: "http://www.example.com/fuchdaten.txt",
                    strings: {
                        ortsname: "Bödefeld",
                        ortstitel: "Fibervillage",
                        knopftitel: "Fuchs aufgepasst!",
                        knopftext: "Jetzt den Fuchs benutzen um Deine Fragen zu klären.",
                        platzhalter: "I bims. Vong Faser her."                    
                    }
                   });                   
    </script>                 

## Beispiel

Ein [vollständiges Beispiel.](../beispiel.html)

    <!DOCTYPE html>
    <head>
    <meta charset="utf-8">
    </head>

    <div id="glasfaserfuchs">
    </div>

    Fuchs. Jetzt!

    <script type="text/html" id="fuchsfragen">
    flyer infomaterial infos zettel flugblatt plakat hallo

    ## Gibt es eigentlich einen neuen Flyer?

    --

    ### Ja. Danke der Nachfrage!

    Der Seba hat wieder einen großartigen und segensreichen Flyer gebaut. Der soll zum Wochenende verteilt werden. Hier kannst Du ihn schon heute anschauen:

    ![Glasfaser-Flyer Nr. 2](http://placeskull.com/300/400)

    [Der Flyer Nr. 2 ganz groß!](http://placeskull.com/500/500)


    ---
    schmuddelbildchen internet avenueq

    ## Wofür braucht man dieses Internet noch gleich?

    --

    <iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/LTJvdGcb7Fs" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>


    ---
    _extra

    Stimmt das auch alles was Du sagst, lieber Glasfaserfuchs?

    --

    Na Klaro! (Angaben ohne Gewähr).
    </script>

    <style>@import url('fuchs.css');</style>
    <script src="fuchs.js"></script>
    <script>

    var fuchs = new Glasfaserfuchs({
        /*src_url: "http://localhost:8000/fragen.txt",*/
        src_element: '#fuchsfragen',
        strings: {
            ortsname: "Bödefeld",
            ortstitel: "Fibervillage",
            knopftitel: "Fuchs aufgepasst!",
            knopftext: "Jetzt den Fuchs benutzen um Deine Fragen zu klären.",
            platzhalter: "I bims. Vong Faser her.",
            carrier_name: "ELENET",
        }
    });

    </script>

    
