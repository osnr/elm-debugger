var editor;

function initEditor() {
    var req = new XMLHttpRequest();
    req.onload = function() {
        finishInitEditor(JSON.parse(this.responseText));
    };
    req.open('GET', '/docs.json?v0.10', true);
    req.send();
}

function finishInitEditor(elmDocs) {
    var embed = Elm.embed(Elm.Editor, document.getElementById("embed"), {
        pTokens: { string: "",
                   type_: null,
                   bounds: { top: 0, left: 0, bottom: 0, right: 0 } },
        slideables: null
    });

    editor = CodeMirror.fromTextArea(
        document.getElementById('input'),
        { lineNumbers: false, // TODO initLines
          matchBrackets: true,
          theme: 'vibrant-ink', // TODO initTheme
          tabMode: 'shift'
          // extraKeys: {
          //     'Ctrl-Enter': compile,
          //     'Shift-Ctrl-Enter': hotSwap,
          //     'Ctrl-H': toggleVerbose,
          //     'Tab': function(cm) {
          //         var spaces = Array(cm.getOption("indentUnit") + 1).join(" ");
          //         cm.replaceSelection(spaces, "end", "+input");
          //     }
          // }
        });
    editor.on('cursorActivity', function() {
        var token = editor.getTokenAt(editor.getCursor(true));

        if (token.type == 'number') {
            embed.ports.slideables.send({
                string: token.string,
                bounds: document.getElementsByClassName('CodeMirror-cursor')[0].getBoundingClientRect()
            });
        } else {
            embed.ports.slideables.send(null);
        }

        embed.ports.pTokens.send({
            string: token.string,
            type_: token.type
        });
    });

    embed.ports.hotSwaps.subscribe(hotSwap);
    embed.ports.compiles.subscribe(compile);
}

function compile() {
    var elmSrc = encodeURIComponent(editor.getValue());
    var request = new XMLHttpRequest();
    request.onreadystatechange = function(e) {
        if (request.readyState === 4
            && request.status >= 200
            && request.status < 300) {

            top.output.document.open();
            top.output.document.write(request.responseText);
            top.output.document.close();
        }
    };
    request.open('POST', '/compile?input=' + elmSrc, true);
    request.setRequestHeader('Content-Type', 'application/javascript');
    request.send();
}

function hotSwap() {
    var request = null;
    if (window.ActiveXObject)  { request = new ActiveXObject("Microsoft.XMLHTTP"); }
    if (window.XMLHttpRequest) { request = new XMLHttpRequest(); }
    request.onreadystatechange = function(e) {
        if (request.readyState === 4
            && request.status >= 200
            && request.status < 300) {
            var result = JSON.parse(request.responseText);
            var top = self.parent;
            var js = result.success;
            if (js) {
                var error = top.output.document.getElementById('ErrorMessage');
                if (error) {
                    error.parentNode.removeChild(error);
                }
                top.output.eval(js);
                var moduleStr = js.substring(0,js.indexOf('=')).replace(/\s/g,'');
                var module = top.output.eval(moduleStr);
                if (top.output.Elm.Debugger) {
                    var debuggerState = top.output.Elm.Debugger.getHotSwapState();
                    top.output.runningElmModule.dispose();
                    top.output.Elm.Debugger.dispose();

                    var wrappedModule = top.output.Elm.debuggerAttach(module, debuggerState);
                    top.output.runningElmModule = top.output.Elm.fullscreen(wrappedModule);
                }
                else {
                    top.output.runningElmModule =
                        top.output.runningElmModule.swap(module);
                }
            }
        }
    };
    var elmSrc = encodeURIComponent(editor.getValue());
    request.open('POST', '/hotswap?input=' + elmSrc, true);
    request.setRequestHeader('Content-Type', 'application/javascript');
    request.send();
}
