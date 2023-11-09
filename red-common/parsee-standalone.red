Red [title: "Standalone version of the ParSEE backend"] 
set [parsee: parse-dump: inspect-dump:] 
reduce bind [:parsee :parse-dump :inspect-dump] 
context [
    once: func [
        "Set value of WORD to VAL only if it's unset" 
        'word [set-word!] 
        val [default!] "New value"
    ] [
        if unset? get/any word [set word :val] 
        :val
    ] 
    default: func [
        "If SUBJ's value is none, set it to VAL" 
        'subj [set-word! set-path!] 
        val [default!] "New value"
    ] [
        if none =? get/any subj [set subj :val] 
        :val
    ] 
    maybe: func [
        {If SUBJ's value is not strictly equal to VAL, set it to VAL (for use in reactivity)} 
        'subj [set-word! set-path!] 
        val [default!] "New value" 
        /same "Use =? as comparator"
    ] [
        if either same [:val =? get/any subj] [:val == get/any subj] [return :val] 
        set subj :val
    ] 
    import: function [
        {Import words from context CTX into the global namespace} 
        ctx [object!] 
        /only words [block!] "Not all, just chosen words"
    ] [
        either only [
            foreach word words [set/any 'system/words/:word :ctx/:word]
        ] [
            set/any bind words-of ctx system/words values-of ctx
        ]
    ] 
    export: function [
        {Export a set of bound words into the global namespace} 
        words [block!]
    ] [
        foreach w words [set/any 'system/words/:w get/any :w]
    ] 
    anonymize: function [
        {Return WORD bound in an anonymous context and set to VALUE} 
        word [any-word!] value [any-type!]
    ] [
        o: construct change [] to set-word! word 
        set/any/only o :value 
        bind word o
    ] 
    assert: none 
    context [
        next-newline?: function [b [block!]] [
            forall b [if new-line? b [return b]] 
            tail b
        ] 
        set 'assert function [
            [no-trace] 
            {Evaluate a set of test expressions, showing a backtrace if any of them fail} 
            tests [block!] {Delimited by new-line, optionally followed by an error message} 
            /local result
        ] [
            while [not tail? tests] [
                set/any 'result do/next bgn: tests 'tests 
                all [
                    :result 
                    any [
                        new-line? tests 
                        tail? tests 
                        all [string? :tests/1 new-line? next tests]
                    ] 
                    continue
                ] 
                end: next-newline? tests 
                if 0 <> left: offset? tests end [
                    if any [
                        left > 1 
                        not string? :tests/1
                    ] [
                        do make error! form reduce [
                            "Assertion is not new-line-aligned at:" 
                            mold/part bgn 100
                        ]
                    ] 
                    tests: end
                ] 
                unless :result [
                    msg: either left = 1 [first end: back end] [""] 
                    print ["ASSERTION FAILED!" msg] 
                    expr: copy/part bgn end 
                    full: any [attempt [to integer! system/console/size/x] 80] 
                    half: to integer! full - 22 / 2 
                    result': mold/flat/part :result half 
                    expr': mold/flat/part :expr half 
                    print ["  Check" expr' "failed with" result' "^/  Reduction log:"] 
                    trace/all expr
                ]
            ] 
            exit
        ]
    ] 
    with: func [
        "Bind CODE to a given context CTX" 
        ctx [any-object! function! any-word! block!] 
        {Block [x: ...] is converted into a context, [x 'x ...] is used as a list of contexts} 
        code [block!]
    ] [
        case [
            not block? :ctx [bind code :ctx] 
            set-word? :ctx/1 [bind code context ctx] 
            'otherwise [foreach ctx ctx [bind code do :ctx] code]
        ]
    ] do reduce [function [] []] 
    thrown: pcatch: fcatch: trap: following: none 
    context [
        with-thrown: func [code [block!] /thrown] [
            do code
        ] 
        set 'thrown func ["Value of the last THROW from FCATCH or PCATCH"] bind [:thrown] :with-thrown 
        set 'pcatch function [
            {Eval CODE and forward thrown value into CASES as 'THROWN'} 
            cases [block!] {CASE block to evaluate after throw (normally not evaluated)} 
            code [block!] "Code to evaluate"
        ] bind [
            with-thrown [
                set/any 'thrown catch [return do code] 
                forall cases [if do/next cases 'cases [break]] 
                if head? cases [throw :thrown] 
                do cases/1
            ]
        ] :with-thrown 
        set 'fcatch function [
            {Eval CODE and catch a throw from it when FILTER returns a truthy value} 
            filter [block!] {Filter block with word THROWN set to the thrown value} 
            code [block!] "Code to evaluate" 
            /handler {Specify a handler to be called on successful catch} 
            on-throw [block!] "Has word THROWN set to the thrown value"
        ] bind [
            with-thrown [
                set/any 'thrown catch [return do code] 
                unless do filter [throw :thrown] 
                either handler [do on-throw] [:thrown]
            ]
        ] :with-thrown 
        set 'trap function [
            {Try to DO a block and return its value or an error} 
            code [block!] 
            /all {Catch also BREAK, CONTINUE, RETURN, EXIT and THROW exceptions} 
            /keep {Capture and save the call stack in the error object} 
            /catch {If provided, called upon exceptiontion and handler's value is returned} 
            handler [block! function!] "func [error][] or block that uses THROWN" 
            /local result
        ] bind [
            with-thrown [
                plan: [set/any 'result do code 'ok] 
                set 'thrown try/:all/:keep plan 
                case [
                    thrown == 'ok [:result] 
                    block? :handler [do handler] 
                    'else [handler thrown]
                ]
            ]
        ] :with-thrown 
        set 'following function [
            {Guarantee evaluation of CLEANUP after leaving CODE} 
            code [block!] "Code that can use break, continue, throw" 
            cleanup [block!] "Finalization code"
        ] [
            do/trace code :cleaning-tracer
        ] 
        cleaning-tracer: func [[no-trace]] bind [[end] do cleanup] :following
    ] do reduce [function [] []] 
    {^/^-;-- this version is simpler but requires explicit `true [throw thrown]` to rethrow values that fail all case tests^/^-;-- and that I consider a bad thing^/^/^-set 'pcatch function [^/^-^-"Eval CODE and forward thrown value into CASES as 'THROWN'"^/^-^-cases [block!] "CASE block to evaluate after throw (normally not evaluated)"^/^-^-code  [block!] "Code to evaluate"^/^-] bind [^/^-^-with-thrown [^/^-^-^-set/any 'thrown catch [return do code]^/^-^-^-case cases^-^-^-^-^-^-^-^-^-;-- case is outside of catch for `throw thrown` to work^/^-^-]^/^-] :with-thrown^/} 
    composite: none 
    context [
        non-paren: charset [not #"("] 
        trap-error: function [on-err [function! string!] :code [paren!]] [
            trap/catch 
            as [] code 
            pick [[on-err thrown] [on-err]] function? :on-err
        ] 
        set 'composite function [
            {Return STR with parenthesized expressions evaluated and formed} 
            ctx [block!] {Bind expressions to CTX - in any format accepted by WITH function} 
            str [any-string!] "String to interpolate" 
            /trap "Trap evaluation errors and insert text instead" 
            on-err [function! string!] "string or function [error [error!]]"
        ] [
            s: as string! str 
            b: with ctx parse s [collect [
                keep ("") 
                any [
                    keep copy some non-paren 
                    | keep [#"(" ahead #"\"] skip 
                    | s: (set [v: e:] transcode/next s) :e 
                    keep (:v)
                ]
            ]] 
            if trap [
                forall b [
                    if paren? b/1 [b: insert b [trap-error :on-err]]
                ]
            ] 
            as str rejoin b
        ]
    ] 
    if native? :function [
        context [
            make-check: function [check [paren!] word [get-word!]] [
                compose/deep [
                    unless (check) [
                        do make error! form reduce [
                            "Failed" (mold check) "for" type? (word) "value:" mold/flat/part (word) 40
                        ]
                    ]
                ]
            ] 
            make-switch: function [word [get-word!] options [block!] values [block! none!]] [
                compose/only pick [[
                    switch/default type? (word) (options) (values)
                ] [
                    switch type? (word) (options)
                ]] block? values
            ] 
            extract-value-checks: function [field [any-word!] types [block!] values [block! none!] /local check words] [
                field: to get-word! field 
                typeset: clear [] 
                options: clear [] 
                parse types [any [
                    copy words some word! (append typeset words) 
                    opt [
                        set check paren! (
                            mask: reduce to block! make typeset! words 
                            append/only append options mask make-check check field
                        )
                    ]
                ]] 
                reduce [copy typeset copy options]
            ] 
            spec-word!: make typeset! [word! lit-word! get-word!] 
            defaults!: make typeset! [
                scalar! series! map! 
                word! lit-word! get-word! refinement! issue!
            ] 
            insert-check: function [
                body [block!] 
                word [get-word!] 
                ref? [logic!] "True if words comes after a refinement" 
                default [defaults! none!] 
                types [block! none!] 
                options [block! none!] 
                general-check [block! none!]
            ] [
                if types [typeset: make typeset! types] 
                if default [
                    default: reduce [to set-word! word default] 
                    logic?: either types [to logic! find typeset logic!] [yes]
                ] 
                need-none-check?: all [ref? either types [not find typeset none!] [no]] 
                check: case [
                    any [not empty? options all [default logic?]] [
                        unless options [options: make block! 2] 
                        if default [insert options reduce [none! default]] 
                        new-line/skip options on 2 
                        make-switch word options general-check
                    ] 
                    all [default general-check] [
                        compose/only [
                            either (word) (general-check) (default)
                        ]
                    ] 
                    default [
                        compose/only [
                            unless (word) (default)
                        ]
                    ] 
                    all [general-check need-none-check?] [
                        compose/only [
                            if (word) (general-check)
                        ]
                    ] 
                    general-check [general-check] 
                    'else [[]]
                ] 
                new-line insert body check on
            ] 
            native-function: :function 
            set 'function native-function [
                {Defines a function, making all set-words in the body local, and with default args and value checks support} 
                spec [block!] body [block!] 
                /local word
            ] [
                ref?: no 
                parse spec: copy spec [any [
                    [set word spec-word! 
                    | not quote return: change set word set-word! (to word! word) 
                    [remove set default defaults! 
                    | pos: (do make error! rejoin ["Invalid default value for '" (word) " at " (mold/flat/part :pos 20)])]] 
                    pos: set types opt block! 
                    opt string! 
                    remove set values opt paren! 
                    (general-check: if values [make-check values to get-word! word] 
                    if types [
                        set [types: options:] extract-value-checks word types general-check 
                        change/only pos types
                    ] 
                    if any [types values default] [
                        insert-check body to get-word! word ref? default types options general-check
                    ] 
                    set [default: values: options: general-check:] none) 
                    | refinement! (ref?: yes) 
                    | skip
                ]] 
                native-function spec body
            ]
        ]
    ] 
    comment [
        probe do probe [f: function [x: 1 [integer! float! (x >= 0)] (x < 0)] [probe x]] 
        probe do probe [f: function [x: 1] [probe x]] 
        probe do probe [f: function [x: 1 (x < 0)] [probe x]] 
        probe do probe [f: function [x: 1 [integer! float!] (x < 0)] [probe x]] 
        probe do probe [f: function [x [integer! float!] (x < 0)] [probe x]] 
        probe do probe [f: function [x: 1 [integer! (x >= 0)]] [probe x]] 
        probe do probe [f: function [/ref x: 1 [integer! (x >= 0) string!] (find x "0")] [probe x]]
    ] 
    set 'exponent-of function [
        {Returns the exponent E of number X = m * (10 ** e), 1 <= m < 10} 
        x [number!]
    ] [
        attempt [to 1 round/floor log-10 absolute to float! x]
    ] 
    format-number: function [
        "Format a number" 
        num [number!] 
        integral [integer!] {Minimal size of integral part (>0 to pad with zero, <0 to pad with space)} 
        frac [integer!] {Exact size of fractional part (0 to remove it, >0 to enforce it, <0 to only use it for non-integer numbers)}
    ] [
        frac: either integer? num [max 0 frac] [absolute frac] 
        expo: any [exponent-of num 0] 
        if percent? num [expo: expo + 2] 
        digits: form absolute num * (10.0 ** (12 - expo)) 
        remove find/last digits #"." 
        if percent? num [take/last digits] 
        if expo < -1 [insert/dup digits #"0" -1 - expo] 
        insert dot: skip digits 1 + expo #"." 
        if 0 < n: (absolute integral) + 1 - index? dot [
            char: pick "0 " integral >= 0 
            insert/dup digits char n 
            dot: skip dot n
        ] 
        clear either frac > 0 [
            dot: change dot #"." 
            append/dup digits #"0" frac - length? dot 
            skip dot frac
        ] [
            dot
        ] 
        if percent? num [append digits #"%"] 
        if num < 0 [insert digits #"-"] 
        digits
    ] 
    timestamp: function [
        {Get date & time in a sort-friendly YYYYMMDD-hhmmss-mmm format} 
        /from dt [date!] "Use provided date+time instead of the current"
    ] [
        dt: any [dt now/precise] 
        r: make string! 32 
        foreach field [year month day hour minute second] [
            append r format-number dt/:field 2 -3
        ] .: 
        skip r 8 .: insert . "-" .: 
        skip . 6 .: change . "-" .: 
        skip . 3 .: clear . 
        r
    ] 
    deep-reactor-92!: none 
    context [
        reduce-deep-change-92: function [owner word target action new index part] [
            f: :owner/on-deep-change-92* 
            switch/default action [
                insert [] 
                inserted [f word target part yes no] 
                append [] 
                appended [f word (p: skip head target index) length? p yes no] 
                change [f word (skip head target index) part no no] 
                changed [f word (skip head target index) part yes no] 
                clear [if part > 0 [f word target part no no]] 
                cleared [f word target part no no] 
                move [f word new part no yes] 
                moved [f word target part yes yes] 
                poke [f word (skip head target index) part no no] 
                poked [f word (skip head target index) part yes no] 
                put [
                    unless tail? next target [
                        f word next target part no no
                    ]
                ] 
                put-ed [f word next target part yes no] 
                random [f word target part no yes] 
                randomized [f word target part yes yes] 
                remove [if part > 0 [f word target part no no]] 
                removed [f word target part no no] 
                reverse [f word target part no yes] 
                reversed [f word target part yes yes] 
                sort [f word target (length? target) no yes] 
                sorted [f word target (length? target) yes yes] 
                swap [f word target part no no] 
                swaped [f word target part yes no] 
                take [f word target part no no] 
                taken [f word target part no no] 
                trim [f word target (length? target) no no] 
                trimmed [f word target (length? target) yes no]
            ] [
                do make error! "Unsupported action in on-deep-change*!"
            ]
        ] 
        set 'deep-reactor-92! make deep-reactor! [
            on-deep-change-92*: func [
                word [word!] "name of the field value of which is being changed" 
                target [series!] "series at removal or insertion point" 
                part [integer!] "length of removal or insertion" 
                insert? [logic!] "true = just inserted, false = about to remove" 
                reordering? [logic!] "removed/inserted items belong to the same series"
            ] [] 
            on-deep-change**: :on-deep-change* 
            on-deep-change*: function [owner word target action new index part] [
                reduce-deep-change-92 owner to word! word target action :new index part 
                on-deep-change** owner word target action :new index part
            ]
        ]
    ] 
    comment 
    {^/^-; test code^/^-r: make deep-reactor-92! [^/^-^-x: "abcd"^/^-^-^/^-^-on-deep-change-92*: func [^/^-^-^-word        [word!]    "name of the field value of which is being changed"^/^-^-^-target      [series!]  "series at removal or insertion point"^/^-^-^-part        [integer!] "length of removal or insertion"^/^-^-^-insert?     [logic!]   "true = just inserted, false = about to remove"^/^-^-^-reordering? [logic!]   "removed items won't leave the series, inserted items came from the same series"^/^-^-^-; done?       [logic!]   "signifies that series is in it's final state (after removal/insertion)"^/^-^-][^/^-^-^-; ...your code to handle changes... e.g.:^/^-^-^-print [^/^-^-^-^-word ":"^/^-^-^-^-either insert? ["inserted"]["removing"]^/^-^-^-^-"at" mold/flat target^/^-^-^-^-part "items"^/^-^-^-^-either reordering? ["(reordering)"][""]^/^-^-^-^-either part = 0 ["(done)"][""]^/^-^-^-^-; either done? ["(done)"][""]^/^-^-^-]^/^-^-]^/^-]^/^-^/^-?? r/x^/^-insert/part next r/x [1 0 1] 2^/^-reverse/part next r/x 2^/^-remove/part next next next r/x 3^/^-?? r/x^/} 
    parsee: inspect-dump: parse-dump: none 
    context expand-directives [
        skip?: func [s [series!]] [-1 + index? s] 
        clone: function [
            "Obtain a complete deep copy of the data" 
            data [any-object! map! series!]
        ] with system/codecs/redbin [
            decode encode data none
        ] 
        keywords: make hash! [
            | skip quote none end 
            opt not ahead 
            to thru any some while 
            if into fail break reject 
            set copy keep collect case 
            remove insert change 
            #[true]
        ] 
        unloadable?: func [w [any-word!]] [any [function? w: context? w w =? system/words]] 
        fallback: func [x [any-type!] y [any-type!]] [any [:y :x]] 
        isolate-rule: function [
            {Split parse rule from local function context for Redbin compatibility} 
            block [block!] 
            /local w v
        ] [
            unique-rules: make hash! 32 
            parse block rule: [
                end 
                | p: if (find/only/same unique-rules head p) to end 
                | p: (append/only unique-rules head p) 
                any [
                    change [set w any-word! if (unloadable? w)] (
                        fallback 
                        w 
                        attempt [
                            set/any 'v get/any w 
                            anonymize w either block? :v [also v parse v rule] [:v]
                        ]
                    ) 
                    | ahead block! into rule 
                    | skip
                ]
            ] 
            block
        ] 
        make-dump-name: function [] [
            if exists? filename: rejoin [%"" timestamp %.pdump] [
                append filename enbase/base to #{} random 2147483647 16
            ] 
            filename
        ] 
        set 'parsee function [
            {Process a series using dialected grammar rules, visualizing progress afterwards} 
            input [any-string!] 
            rules [block!] 
            /case "Uses case-sensitive comparison" 
            /part "Limit to a length or position" 
            length [number! series!] 
            /timeout {Force failure after certain parsing time is exceeded} 
            maxtime [time! integer! float!] "Time or number of seconds (defaults to 1 second)" 
            /keep "Do not remove the temporary dump file" 
            /auto "Only visualize failed parse runs"
        ] [
            path: to-red-file to-file any [get-env 'TEMP get-env 'TMP %.] 
            file: make-dump-name 
            parse-result: apply 'parse-dump [
                input rules 
                /case case 
                /part part length 
                /timeout timeout maxtime 
                /into on path/:file
            ] 
            unless all [auto parse-result] [inspect-dump path/:file] 
            unless keep [delete path/:file] 
            parse-result
        ] 
        config: none 
        default-config: #(
            tool: "parsee"
        ) 
        set 'inspect-dump function [
            "Inspect a parse dump file with PARSEE tool" 
            filename [file!]
        ] [
            filename: to-local-file filename 
            self/config: any [
                config 
                attempt [make map! load/all %parsee.cfg] 
                default-config
            ] 
            call-result: call/shell/wait/output command: rejoin ["" (config/tool) { "} (filename) {"}] output: make "" 64 
            if call-result <> 0 [
                print rejoin ["Call to '" (command) "' failed with code " (call-result) "."] 
                if object? :system/view [
                    if tool: request-file/title "Locate PARSEE tool..." [
                        config/tool: rejoin [{"} (to-local-file tool) {"}] 
                        call-result: call/shell/wait command: rejoin ["" (config/tool) { "} (filename) {"}] 
                        either call-result = 0 [
                            save %parsee.cfg mold/only to [] config
                        ] [
                            print rejoin ["Call to '" (command) "' failed with code " (call-result) "."]
                        ]
                    ]
                ] 
                if call-result <> 0 [
                    print rejoin [{Ensure 'parsee' command is available on PATH, or manually open the saved dump with it.}] 
                    print rejoin ["Parsing dump was saved as '" (filename) "'.^/"]
                ]
            ] 
            exit
        ] 
        set 'parse-dump function [
            {Process a series using dialected grammar rules, dumping the progress into a file} 
            input [binary! any-block! any-string!] 
            rules [block!] 
            /case "Uses case-sensitive comparison" 
            /part "Limit to a length or position" 
            length [number! series!] 
            /timeout "Specify deadlock detection timeout" 
            maxtime: 0:00:01 [time! integer! float!] "Time or number of seconds (defaults to 1 second)" 
            /into filename: (make-dump-name) [file!] "Override automatic filename generation"
        ] [
            cloned: clone input 
            changes: make [] 64 
            events: make [] 512 
            limit: now/utc/precise + to time! maxtime 
            age: 0 
            reactor: make deep-reactor-92! [
                tracked: input 
                on-deep-change-92*: :logger
            ] 
            following [parse/:case/:part/trace input rules length :tracer] [
                data: reduce [
                    cloned 
                    new-line/all/skip events on 5 
                    changes
                ] 
                save/as filename isolate-rule data 'redbin
            ]
        ] 
        tracer: function [event [word!] match? [logic!] rule [block!] input [series!] stack [block!] /extern age] with :parse-dump [
            reduce/into [age: age + 1 input event match? rule] tail events 
            not all [age % 20 = 0 now/utc/precise > limit]
        ] 
        logger: function [
            word [word!] "name of the field value of which is being changed" 
            target [series!] "series at removal or insertion point" 
            part [integer!] "length of removal or insertion" 
            insert? [logic!] "true = just inserted, false = about to remove" 
            reordering? [logic!] {removed items won't leave the series, inserted items came from the same series}
        ] with :parse-dump [
            if zero? part [exit] 
            action: pick [insert remove] insert? 
            repend changes [
                age 
                pick [insert remove] insert? 
                skip? target 
                copy/part target part
            ]
        ]
    ]
]