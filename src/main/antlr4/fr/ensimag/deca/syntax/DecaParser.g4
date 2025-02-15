parser grammar DecaParser;

options {
    // Default language but name it anyway
    //
    language  = Java;

    // Use a superclass to implement all helper
    // methods, instance variables and overrides
    // of ANTLR default methods, such as error
    // handling.
    //
    superClass = AbstractDecaParser;

    // Use the vocabulary generated by the accompanying
    // lexer. Maven knows how to work out the relationship
    // between the lexer and parser and will build the
    // lexer before the parser. It will also rebuild the
    // parser if the lexer changes.
    //
    tokenVocab = DecaLexer;

}

// which packages should be imported?
@header {
    import fr.ensimag.deca.tree.*;
    import java.io.PrintStream;
    import fr.ensimag.deca.tools.SymbolTable;
}

@members {
    @Override
    protected AbstractProgram parseProgram() {
        return prog().tree;
    }

    private SymbolTable symbolTable = new SymbolTable();
}

prog returns[AbstractProgram tree]
    : list_classes main EOF {
            assert($list_classes.tree != null);
            assert($main.tree != null);
            $tree = new Program($list_classes.tree, $main.tree);
            setLocation($tree, $list_classes.start);
        }           // pour les assert, Verification des attributs ( pas indispensable , mais aide au debug )
                    // ensuite Construction de l’arbre
                    // Et enfin Initialisation du champ ’location’ de l’arbre $tree a partir du jeton $main
    ;

main returns[AbstractMain tree]
    : /* epsilon */ {
            $tree = new EmptyMain();
        }
    | block {
            assert($block.decls != null);
            assert($block.insts != null);
            $tree = new Main($block.decls, $block.insts);
            setLocation($tree, $block.start);
        }
    ;

block returns[ListDeclVar decls, ListInst insts]
    : OBRACE list_decl list_inst CBRACE {
            assert($list_decl.tree != null);
            assert($list_inst.tree != null);
            $decls = $list_decl.tree;
            $insts = $list_inst.tree;
        }
    ;

list_decl returns[ListDeclVar tree]  // tree est ici une liste d’arbres
@init {
    $tree = new ListDeclVar();
    
    }
    : decl_var_set[$tree]*
    ;

decl_var_set[ListDeclVar l]
    : type list_decl_var[$l,$type.tree] SEMI
    ;

list_decl_var[ListDeclVar l, AbstractIdentifier t]
    : dv1=decl_var[$t] { $l.add($dv1.tree); }
     (COMMA dv2=decl_var[$t] { $l.add($dv2.tree); })*  //Si il y a plusieurs éléments dans la liste, on les ajoute aussi.
    ;

decl_var[AbstractIdentifier t] returns[AbstractDeclVar tree]
@init {
    AbstractInitialization initialisation;                                        
    }
    : i=ident {initialisation = new NoInitialization(); }  //ident renvoie un AbstractIdentifier tree, c'est le nom de la variable (varname).
      (EQUALS e=expr {
        initialisation = new Initialization($e.tree);
        setLocation(initialisation, $e.start);
        })?  // expr renvoie un AbstractExpr tree
      {
        $tree = new DeclVar($t, $i.tree, initialisation); 
        setLocation($tree, $i.start);
      }
    ;

list_inst returns[ListInst tree]
@init {
    $tree = new ListInst();
    } // on initialise l'arbre que l'on va renvoyer
    : (inst {
            assert($inst.tree != null);
            $tree.add($inst.tree);
        })* 
    ;

inst returns[AbstractInst tree]
    : e1=expr SEMI {
        assert($e1.tree != null);
        $tree = $e1.tree;
        setLocation($tree, $e1.start);    
        }  // $e1.tree est de type AbstractExpr qui hérite de AbstractInst

    | SEMI {
        $tree = new NoOperation();
        } //quand il y a juste un ';' on renvoie un 'NoOperation'

    | PRINT OPARENT list_expr CPARENT SEMI {
            assert($list_expr.tree != null);
            $tree = new Print(false, $list_expr.tree);
            setLocation($tree, $PRINT);
        } //list_expr.tree est de type ListExpr
          // Print hérite de AbstractPrint qui hérite de AbstractInst

    | PRINTLN OPARENT list_expr CPARENT SEMI {
            assert($list_expr.tree != null);
            $tree = new Println(false, $list_expr.tree);
            setLocation($tree, $PRINTLN);
        }

    | PRINTX OPARENT list_expr CPARENT SEMI {
            assert($list_expr.tree != null);
            $tree = new Print(true, $list_expr.tree);
            setLocation($tree, $PRINTX);
        }

    | PRINTLNX OPARENT list_expr CPARENT SEMI {
            assert($list_expr.tree != null);
            $tree = new Println(true, $list_expr.tree);
            setLocation($tree, $PRINTLNX);
        }

    | if_then_else {
            assert($if_then_else.tree != null);
            $tree = $if_then_else.tree;
        }

    | WHILE OPARENT condition=expr CPARENT OBRACE body=list_inst CBRACE {
            assert($condition.tree != null);
            assert($body.tree != null);
            $tree = new While($condition.tree, $body.tree);
            setLocation($tree, $WHILE);
        }

    | RETURN expr SEMI {
            assert($expr.tree != null);
            $tree = new Return($expr.tree);
            setLocation($tree, $RETURN);
        } 
    ;

if_then_else returns[IfThenElse tree] 
@init {
    IfThenElse elseTree;

}
    : if1=IF OPARENT condition=expr CPARENT OBRACE li_if=list_inst CBRACE {
        ListInst elselist = new ListInst();
        $tree = new IfThenElse($condition.tree, $li_if.tree, elselist);
        setLocation($tree, $if1);
        }
      (ELSE elsif=IF OPARENT elsif_cond=expr CPARENT OBRACE elsif_li=list_inst CBRACE {
        ListInst elseiflist = new ListInst();
        elseTree = new IfThenElse($elsif_cond.tree, $elsif_li.tree, elseiflist);
        setLocation(elseTree, $elsif);
        elselist.add(elseTree);
        elselist = elseiflist;
        }
      )*
      (ELSE OBRACE li_else=list_inst CBRACE {
        for (AbstractInst elem : ($li_else.tree).getList()){
            elselist.add(elem);
        }
        setLocation(elselist, $li_else.start);
        }
      )?
    ;

list_expr returns[ListExpr tree]
@init {
    $tree = new ListExpr();
    }
    : (e1=expr {
        assert($e1.tree != null);
        $tree.add($e1.tree);
        }
      (COMMA e2=expr {
        assert($e2.tree != null);
        $tree.add($e2.tree);
        })* )?
    ;

expr returns[AbstractExpr tree]
    : assign_expr {
            assert($assign_expr.tree != null);
            $tree = $assign_expr.tree;
        }
    ;

assign_expr returns[AbstractExpr tree]
    : e=or_expr (
        /* condition: expression e must be a "LVALUE" */ 
        {
            if (! ($e.tree instanceof AbstractLValue)) {
                throw new InvalidLValue(this, $ctx);
            }
        }
        EQUALS e2=assign_expr {
            assert($e.tree != null);
            assert($e2.tree != null);
            $tree =  new Assign((AbstractLValue)$e.tree, $e2.tree);
            setLocation($tree, $EQUALS);
        } // on fait un cast (marche car on a vérifié avant que $e.tree était de type AbstractLValue)
      | /* epsilon */ {
            assert($e.tree != null);
            $tree = $e.tree;
        }
      )
    ;

or_expr returns[AbstractExpr tree]
    : e=and_expr {
            assert($e.tree != null);
            $tree = $e.tree;
        }
    | e1=or_expr OR e2=and_expr {
            assert($e1.tree != null);
            assert($e2.tree != null);
            $tree = new Or($e1.tree, $e2.tree);
            setLocation($tree, $OR);
       }
    ;

and_expr returns[AbstractExpr tree]  
    : e=eq_neq_expr {
            assert($e.tree != null);
            $tree = $e.tree;
        }
    |  e1=and_expr AND e2=eq_neq_expr {
            assert($e1.tree != null);                         
            assert($e2.tree != null);
            $tree = new And($e1.tree, $e2.tree);
            setLocation($tree, $AND);
        }
    ;

eq_neq_expr returns[AbstractExpr tree] 
    : e=inequality_expr {
            assert($e.tree != null);
            $tree = $e.tree;
        }
    | e1=eq_neq_expr EQEQ e2=inequality_expr {
            assert($e1.tree != null);
            assert($e2.tree != null);
            $tree = new Equals($e1.tree, $e2.tree);
            setLocation($tree, $EQEQ);
        }
    | e1=eq_neq_expr NEQ e2=inequality_expr {
            assert($e1.tree != null);
            assert($e2.tree != null);
            $tree = new NotEquals($e1.tree, $e2.tree);
            setLocation($tree, $NEQ);
        }
    ;

inequality_expr returns[AbstractExpr tree] 
    : e=sum_expr {
            assert($e.tree != null);
            $tree = $e.tree;
        }
    | e1=inequality_expr LEQ e2=sum_expr {
            assert($e1.tree != null);
            assert($e2.tree != null);
            $tree = new LowerOrEqual($e1.tree, $e2.tree);
            setLocation($tree, $LEQ);
        }
    | e1=inequality_expr GEQ e2=sum_expr {
            assert($e1.tree != null);
            assert($e2.tree != null);
            $tree = new GreaterOrEqual($e1.tree, $e2.tree);
            setLocation($tree, $GEQ);
        }
    | e1=inequality_expr GT e2=sum_expr {
            assert($e1.tree != null);
            assert($e2.tree != null);
            $tree = new Greater($e1.tree, $e2.tree);
            setLocation($tree, $GT);
        }
    | e1=inequality_expr LT e2=sum_expr {
            assert($e1.tree != null);
            assert($e2.tree != null);
            $tree = new Lower($e1.tree, $e2.tree);
            setLocation($tree, $LT);
        }
    | e1=inequality_expr INSTANCEOF type {
            assert($e1.tree != null);
            assert($type.tree != null);
            $tree = new InstanceOf($e1.tree, $type.tree);
            setLocation($tree, $INSTANCEOF);
        }
    ;


sum_expr returns[AbstractExpr tree]
    : e=mult_expr {
            assert($e.tree != null);
            $tree = $e.tree;
        }
    | e1=sum_expr PLUS e2=mult_expr {
            assert($e1.tree != null);
            assert($e2.tree != null);
            $tree = new Plus($e1.tree, $e2.tree);
            setLocation($tree, $PLUS);
        }
    | e1=sum_expr MINUS e2=mult_expr {
            assert($e1.tree != null);
            assert($e2.tree != null);
            $tree = new Minus($e1.tree, $e2.tree);
            setLocation($tree, $MINUS);
        }
    ;

mult_expr returns[AbstractExpr tree] 
    : e=unary_expr {
            assert($e.tree != null);
            $tree = $e.tree;
        }
    | e1=mult_expr TIMES e2=unary_expr {
            assert($e1.tree != null);                                         
            assert($e2.tree != null);
            $tree = new Multiply($e1.tree, $e2.tree);
            setLocation($tree, $TIMES);
        }
    | e1=mult_expr SLASH e2=unary_expr {
            assert($e1.tree != null);                                         
            assert($e2.tree != null);
            $tree = new Divide($e1.tree, $e2.tree);
            setLocation($tree, $SLASH);
        }
    | e1=mult_expr PERCENT e2=unary_expr {
            assert($e1.tree != null);                                                                          
            assert($e2.tree != null);
            $tree = new Modulo($e1.tree, $e2.tree);
            setLocation($tree, $PERCENT);
        }
    ;

unary_expr returns[AbstractExpr tree] 
    : op=MINUS e=unary_expr {
            assert($e.tree != null);
            $tree = new UnaryMinus($e.tree);
            setLocation($tree, $op);
        }
    | op=EXCLAM e=unary_expr {
            assert($e.tree != null);
            $tree = new Not($e.tree);
            setLocation($tree, $op);
        }
    | select_expr {
            assert($select_expr.tree != null);
            $tree = $select_expr.tree;
        }
    ;

select_expr returns[AbstractExpr tree]  // à faire, j'ai pas compris la fin
    : e=primary_expr {
            assert($e.tree != null);
            $tree = $e.tree;
        }
    | e1=select_expr DOT i=ident {
            assert($e1.tree != null);
            assert($i.tree != null);
        }  // i.tree est un AbstractIdentifier qui hérite de AbstractLvalue qui hérite de AbstractExpr
        (o=OPARENT args=list_expr CPARENT {
            // we matched "e1.i(args)"
            assert($args.tree != null);
            $tree = new MethodCall($e1.tree, $i.tree, $args.tree);
            setLocation($tree, $DOT);
        }
        | /* epsilon */ {
            // we matched "e.i"
            $tree = new Selection($e1.tree, $i.tree);
            setLocation($tree, $DOT);
        }
        )
    ;

primary_expr returns[AbstractExpr tree]  
    : ident {
            assert($ident.tree != null);
            $tree = $ident.tree;
        } // ident.tree est un AbstractIdentifier qui hérite de AbstractLvalue qui hérite de AbstractExpr
    | m=ident OPARENT args=list_expr CPARENT {
            assert($args.tree != null);
            assert($m.tree != null);
        }
    | OPARENT expr CPARENT {
            assert($expr.tree != null);
            $tree = $expr.tree;
            setLocation($tree, $OPARENT);
        }
    | READINT OPARENT CPARENT {
            $tree = new ReadInt();
            setLocation($tree, $READINT);
        }
    | READFLOAT OPARENT CPARENT {
            $tree = new ReadFloat();
            setLocation($tree, $READFLOAT);
        }
    | NEW ident OPARENT CPARENT {
            assert($ident.tree != null);
            $tree = new New($ident.tree);
            setLocation($tree, $ident.start);
        }
    | cast=OPARENT type CPARENT OPARENT expr CPARENT {
            assert($type.tree != null);
            assert($expr.tree != null);
        }
    | literal {
            assert($literal.tree != null);
            $tree = $literal.tree;
        }
    ;

type returns[AbstractIdentifier tree]
    : ident {
            assert($ident.tree != null);
            $tree = $ident.tree;
            setLocation($tree, $ident.start);
        }
    ;

literal returns[AbstractExpr tree] //à finir et penser à rajouter des erreurs cohérentes, prendre exemple sur INT.
    : INT {
            try {
                $tree = new IntLiteral(Integer.parseInt($INT.text));
                setLocation($tree, $INT);
            } catch (NumberFormatException e) {
                $tree = null;
            }
        } {$tree != null}? 
                // The integer could not be parsed (probably it's too large).
                // set $tree to null, and then fail with the semantic predicate
                // {$tree != null}?. In decac, we'll have a more advanced error
                // management.
                // L'instruction {$tree != null}? vérifie que tree est bien différent de null, càd qu'on n'est pas rentré dans l'erreur
    | fd=FLOAT {
            try {
                $tree = new FloatLiteral(Float.parseFloat($fd.text));
                setLocation($tree, $fd);
            } catch (NumberFormatException e) {
                $tree = null;
            }
        } {$tree != null}?
    | s=STRING {
            String stringSansGuillemets = $s.text.substring(1, $s.text.length() - 1);
            $tree = new StringLiteral(stringSansGuillemets);
            setLocation($tree, $s);
        }
    | TRUE {
            $tree = new BooleanLiteral(true);
            setLocation($tree, $TRUE);
        }
    | FALSE {
            $tree = new BooleanLiteral(false);
            setLocation($tree, $FALSE);
        }
    | THIS { // attribut est true ssi le noeud a été ajouté pendant l'analyse syntaxique sans que le programme source ne contienne le mot clé this (ex : m() pour dire this.m()) cf page 62
            $tree = new This(true);
            setLocation($tree, $THIS);
        
        }
    | NULL {
            $tree = new Null(true);
            setLocation($tree, $NULL);
        }
    ;

ident returns[AbstractIdentifier tree]  
    // Nécéssite la déclaration dans @members d'un objet SymbolTable
    : i=IDENT {
            $tree = new Identifier(symbolTable.create($i.text));
            setLocation($tree, $i);
        }
    ;

/****     Class related rules     ****/

list_classes returns[ListDeclClass tree]
@init {
    $tree = new ListDeclClass();
    }
    :
      (c1=class_decl {
            assert($c1.tree != null);
            $tree.add($c1.tree);
        }
      )*
    ;

class_decl returns[AbstractDeclClass tree] 
    : CLASS name=ident superclass=class_extension OBRACE class_body CBRACE {
            assert($name.tree != null);
            assert($superclass.tree != null);
            assert($class_body.listDeclField != null);
            assert($class_body.listDeclMethod != null);
            $tree = new DeclClass($name.tree, $superclass.tree, $class_body.listDeclField ,$class_body.listDeclMethod);
            setLocation($tree, $name.start);
        }
    ;

class_extension returns[AbstractIdentifier tree]
@init {
}
    : EXTENDS ident {
            assert($ident.tree != null);
            $tree = $ident.tree; 
            setLocation($tree, $ident.start);
        }
    | /* epsilon */ { 
            $tree = new Identifier(symbolTable.create("Object"));
            $tree.setLocation(Location.BUILTIN);
        }
    ;

class_body returns[ListDeclField listDeclField, ListDeclMethod listDeclMethod]
@init {
    $listDeclField = new ListDeclField();
    $listDeclMethod = new ListDeclMethod();
    }    
    : (m=decl_method {
            assert($decl_method.method != null);
            $listDeclMethod.add($m.method);
        }
      | decl_field_set[$listDeclField]
      )*
    ;

decl_field_set[ListDeclField l]
    : v=visibility t=type list_decl_field[$v.tree, $t.tree, $l]
      SEMI
    ;

visibility returns[Visibility tree]
    : /* epsilon */ {
            $tree = Visibility.PUBLIC;
        }
    | PROTECTED {
            $tree = Visibility.PROTECTED;
        }
    ;

list_decl_field[Visibility v, AbstractIdentifier t, ListDeclField l]
    : dv1=decl_field[$v, $t] {
            assert($dv1.tree != null);
            $l.add($dv1.tree);
        }
        (COMMA dv2=decl_field[$v, $t] {
            $l.add($dv2.tree);
        }
      )*
    ;

decl_field[Visibility v, AbstractIdentifier t] returns[AbstractDeclField tree]
@init {
    AbstractInitialization initialization;
}
    : i=ident {
            assert($i.tree != null);
            initialization = new NoInitialization();
        }
      (EQUALS e=expr {
            assert($e.tree != null);
            initialization = new Initialization($e.tree);
            setLocation(initialization, $e.start);
        }
      )? {
            $tree = new DeclField($v, $t, $i.tree, initialization);
            setLocation($tree, $i.start);
        }
    ;

decl_method returns[AbstractDeclMethod method]
@init {
    AbstractMethodBody body;
}
    : type ident OPARENT params=list_params CPARENT (block {
            assert($block.decls != null);
            assert($block.insts != null);
            assert($type.tree != null);
            assert($ident.tree != null);
            assert($params.listOfParams != null);
            body = new MethodBody($block.decls, $block.insts);
            setLocation(body, $block.start);
        }
      | ASM OPARENT code=multi_line_string CPARENT SEMI {
            // a changer    
            body = new AsmMethodBody($code.text);
            body.setLocation($code.location); 
        }
      ) {
            $method = new DeclMethod($type.tree, $ident.tree, $list_params.listOfParams, body);
            setLocation($method, $type.start);
        }
    ;

list_params returns[ListDeclParam listOfParams]
@init {
    $listOfParams = new ListDeclParam();
}
    : (p1=param {
            assert($p1.tree != null);
            $listOfParams.add($p1.tree);
        } (COMMA p2=param {
            assert($p2.tree != null);
            $listOfParams.add($p2.tree);
        }
      )*)?
    ;
    
multi_line_string returns[String text, Location location]
    : s=STRING {
            $text = $s.text;
            $location = tokenLocation($s);
        }
    | s=MULTI_LINE_STRING {
            $text = $s.text;
            $location = tokenLocation($s);
        }
    ;

param returns[AbstractDeclParam tree]
    : type ident {
            assert($type.tree != null);
            assert($ident.tree != null);
            $tree = new DeclParam($type.tree, $ident.tree);
            setLocation($tree, $type.start);
        }
    ;