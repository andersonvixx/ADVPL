#Include "APWEBEX.CH"

//----------------------------------------------------------------------------//
// Pagina simples. (http://127.0.0.1/pp/u_ASP1.apw)
//----------------------------------------------------------------------------//
User Function ASP1()

Local cHtml := ""

// A fun��o VldASP1 executa uma valida��o e inicializa a variavel cHtml.
// Se cHtml ficar vazia, � porque passou pela valida��o. Caso contrario,
// a sequencia do programa ser� desviada para WEB EXTENDED END, e ser�
// retornado ao browser o html retornado pela fun��o VldASP1.
WEB EXTENDED INIT cHtml Start "u_VldASP1"

cHtml += ExecInPage("235_ASP1")

WEB EXTENDED END

Return cHtml

//----------------------------------------------------------------------------//
User Function VldASP1()

Local cHtml := ""
Local lOk

// Aqui dever�o ser verificadas as condi��es para a permiss�o de acesso � p�gina. 
// Poderia, por exemplo, verificar se a sess�o est� ativa, dependendo de uma
// condi��o qualquer, por exemplo, se um campo est� preenchido com um determinado valor.
lOk := .T.

If !lOk
   cHtml := "P�gina expirada!"
   cHtml += "<p> Voc� ser� redirecionado para a p�gina de Login."
EndIf

Return cHtml
