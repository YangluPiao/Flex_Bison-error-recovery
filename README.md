# Flex/Bison Error Recovery
### 0. Introduction
This repository shows how [error recovery](https://www.gnu.org/software/bison/manual/html_node/Error-Recovery.html) works in Flex/Bison.  
### 1. Calculator
The most stupid calculator because it only suports `+` operator, but still enough for doing error recovery. Including [scanner.l](scanner.l), [parser.y](parser.y) and of course, the [Makefile](Makefile) and the [sample input file](test.cal).
### 2. Error recovery
The input test case is:
```
1;
1+2;
3+4;
5 6
7
8+9;
```
#### 2.1 Disabled
When error recovery is not used:
```
statement:
          statement expr ';'  {cout << $2 << endl; }
        | expr ';'            {cout << $1 << endl; }
```
the result will be:
```
DAMN IT! syntax error near ;
yyparse value: 1
```
which means our test program is terminated by parser immediately after hitting the syntax error, and the return value of `yyparse()` is 1.
#### 2.2 Enabled
With error recovery enabled:
```
statement:
          statement expr ';'  {cout << $2 << endl; }
        | expr ';'            {cout << $1 << endl; }
        | error
```
the result will be:
```
DAMN IT! syntax error near ;
3
7
DAMN IT! syntax error near 6
17
yyparse value: 0
```
so here `error` is a accaptable token for `statement`, the only thing `yyerror()` do is print the error but not terminate the program. So the return value is 0 for `yyparse()`, instead of 1.
#### 2.3 `error`
`error` is a magic. It can eat up following tokens until hits a specific one given by user. 

If we do something like this:
```
statement:
          statement expr ';'  {cout << $2 << endl; }
        | expr ';'            {cout << $1 << endl; }
        | error ';'
;
```
Then then result will be:
```
DAMN IT! syntax error near ;
3
7
DAMN IT! syntax error near 6
yyparse value: 0
```
We see that everything after `3+4;` is eaten up by `error`, even the result of a correct expr, `8+9;`, is not shown. So be cautious when using this method to eat up following tokens. 

Moreover, the reason why we put the `error` under `statement` is because every syntax error that happens in either `expr` or `term`(rules under `statement`) will reduce according this rule. Which means after handling these errors, parser will resume parsing at the level of a `statement`(that is so called 'recovery'). User can definitely put `error` under `expr` or `term`, but in those cases the parser will become much more complicated, since user needs to consider where and how a syntax error could happen for every 'low-level' tokens and rules. 
#### 2.4 `yyerrok`
`yyerrok` is a macro used for error recovery. Some details about it could be found [here](https://www.ibm.com/support/knowledgecenter/SSLTBW_1.13.0/com.ibm.zos.r13.bpxa600/bpxza68060.htm).

In short, using this macro means parser believes you that you have properly managed the syntax error, so it will skip next three tokens that are causing consecutive syntax errors, which means it won't trigger any `yyerror()`s for those errors. 

Here is the example:
```
statement:
          statement expr ';'  {cout << $2 << endl; }
        | expr ';'            {cout << $1 << endl; }
        | error               { yyerrok;  }
```
and the result is an infinite loop:
```
DAMN IT! syntax error near ;
DAMN IT! syntax error near ;
DAMN IT! syntax error near ;
DAMN IT! syntax error near ;
...
```
the reason is that the very first `;` causes a syntax error. With `yyerrok`, the parser will use this `;` to match rules once again, but unfortunately this is again a syntax error, so the parser is stuck in an infinite loop. To avoid this situation, there is another macro called `yyclearin`.
#### 2.5 `yyclearin`
This is another useful macro for error recovery, see [here](https://www.ibm.com/support/knowledgecenter/SSLTBW_1.13.0/com.ibm.zos.r13.bpxa600/bpxza68059.htm#wq131).

In a word, the parser will eat up the token that causes syntax error, and use next token for further parsing.

As I said before, this will cause an infinite loop:
```
statement:
          statement expr ';'  {cout << $2 << endl; }
        | expr ';'            {cout << $1 << endl; }
        | error               {yyerrok;}
;
```
but with `yyclearin`:
```
statement:
          statement expr ';'  {cout << $2 << endl; }
        | expr ';'            {cout << $1 << endl; }
        | error               {yyerrok;yyclearin;}
;
```
the result will be:
```
DAMN IT! syntax error near ;
3
7
DAMN IT! syntax error near 6
DAMN IT! syntax error near 8
DAMN IT! syntax error near +
DAMN IT! syntax error near ;
yyparse value: 0
```
Notice that `8` is also causing a syntax error. This is a little bit complicated. 

After parsing `3+4;`, the parser hits a `5`, and then looks for a `+`, but what it actually gets is a `6`, so it will report the error is `near 6`. Then it hits a `7`, again, it will look for a `+`, but here comes an `8`, BOOM, syntax error. But since `yyclearin` is enabled, parser will eat up `8`, so for the last `expr`, it will be something like `+9;` which is definitely an invalid expr, so the result `17` is not shown.

### 3. References
[Flex and Bison](http://aquamentus.com/flex_bison.html)
[GNU Bison](https://www.gnu.org/software/bison/)
[Error Handling](http://docs.oracle.com/cd/E19504-01/802-5880/6i9k05dh4/index.html)
[Unix System Services Programming Tools](https://www.ibm.com/support/knowledgecenter/SSLTBW_1.13.0/com.ibm.zos.r13.bpxa600/toc.htm)

