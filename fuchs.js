
import { Elm } from './src/Main.elm'

import glasfaserfuchs from './glasfaserfuchs.png'

import loading from './loading-bars.svg'

/* import wapp from './wapp.svg' */

import glafaavatar from './glafaavatar.png'

import './fuchs.css'

export default function Glasfaserfuchs(options) {

    var get_stichwort = function () {
        var stichwort = location.hash;
        if (stichwort) {
            stichwort = decodeURIComponent(stichwort.substr(1));
        }
        return stichwort;
    }

    var start_fuchs = function(node, answer_text) {
        var d = new Date();
        var utcOff = d.getTimezoneOffset();


        var fuchs = Elm.Main.init({
            node: node,
            flags: {
                time: Date.now(),
                stichwort: get_stichwort(),
                answers: answer_text,
                images: {
                    "fuchs": glasfaserfuchs,
                    "loading": loading,
                    "glafaavatar": glafaavatar
                    /*            ,"wapp": wapp*/
                },
                strings: options.strings || {},
                utcOffset: utcOff,
                startOpen: window.location.href.indexOf("?gff", 0) !== -1
            }
        });

        fuchs.ports.updateStichwort.subscribe(function (stichwort) {
            if (history.pushState) {
                if (stichwort && stichwort != get_stichwort()) {
                    history.pushState(null, null, '?gff#' + stichwort);
                }
            } else {
                location.hash = stichwort;
            }
        });

        window.addEventListener('hashchange', function () {
            fuchs.ports.stichwortChanged.send(get_stichwort());
            /* window.scrollTo(0, 0);*/

        }, false);


        setInterval(function () {
            fuchs.ports.timeChanged.send(Date.now())
        }, 1000);

        return fuchs;
    };



    var answers = "";

    var node_selector = options.node || '#glasfaserfuchs';
    var node = document.querySelector(node_selector);

    if (node === "undefined") {
        throw "Fuchsbau nicht gefunden: " + options.node
    }

    var that = this;

    if (options.src_element) {
        answers = document.querySelector(options.src_element).text;
        that.fuchs = start_fuchs(node, answers);
    } else if (options.src_url) {
        fetch(options.src_url).then(function (response) {
            return response.text();
        }).then(function(txt) {
            answers = txt;
            that.fuchs = start_fuchs(node, answers);
        })
    }


}

/* dirty... but parcel2 is not ready yet it appears */
window.Glasfaserfuchs = Glasfaserfuchs
