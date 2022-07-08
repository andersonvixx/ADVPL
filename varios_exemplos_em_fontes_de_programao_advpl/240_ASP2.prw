#Include "APWEBEX.CH"

//----------------------------------------------------------------------------//
// Metodo POST.
//----------------------------------------------------------------------------//
User Function ASP2()

Local cHtml := ""

WEB EXTENDED INIT cHtml

// Na primeira vez, vai estar vazio.
// A partir da segunda vez, contera' o que o usuario preencheu.
If !Empty(HttpPost->Campo1)
   ConOut(HttpPost->Campo1)       // Exibe na Console do Servidor.
Endif

cHtml += ExecInPage("245_ASP2")

WEB EXTENDED END

Return cHtml
