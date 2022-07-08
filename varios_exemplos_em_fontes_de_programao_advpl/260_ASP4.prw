#Include "APWEBEX.CH"

//----------------------------------------------------------------------------//
// Uso de variaveis SESSION. Comandos AdvPL dentro do HTML.
//----------------------------------------------------------------------------//
User Function ASP4()

Local cHtml := ""

WEB EXTENDED INIT cHtml

HttpSession->dData := Date()
HttpSession->cHora := Time()

HttpSession->aSemana := {"Domingo", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"}

If ValType(HttpSession->i) == "U"
   HttpSession->i := 1
 Else
   HttpSession->i++
EndIf

cHtml += ExecInPage("265_ASP4")

WEB EXTENDED END

Return cHtml
