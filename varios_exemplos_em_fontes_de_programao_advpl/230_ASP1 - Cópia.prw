#Include "APWEBEX.CH"

//----------------------------------------------------------------------------//
// Pagina simples. (http://127.0.0.1/pp/u_ASP1.apw)
//----------------------------------------------------------------------------//
User Function ASP1()

Local cHtml := ""

// A função VldASP1 executa uma validação e inicializa a variavel cHtml.
// Se cHtml ficar vazia, é porque passou pela validação. Caso contrario,
// a sequencia do programa será desviada para WEB EXTENDED END, e será
// retornado ao browser o html retornado pela função VldASP1.
WEB EXTENDED INIT cHtml Start "u_VldASP1"

cHtml += ExecInPage("235_ASP1")

WEB EXTENDED END

Return cHtml

//----------------------------------------------------------------------------//
User Function VldASP1()

Local cHtml := ""
Local lOk

// Aqui deverão ser verificadas as condições para a permissão de acesso à página. 
// Poderia, por exemplo, verificar se a sessão está ativa, dependendo de uma
// condição qualquer, por exemplo, se um campo está preenchido com um determinado valor.
lOk := .T.

If !lOk
   cHtml := "Página expirada!"
   cHtml += "<p> Você será redirecionado para a página de Login."
EndIf

Return cHtml
