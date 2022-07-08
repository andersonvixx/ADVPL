#Include "APWEBEX.CH"
#Include "TbiConn.ch"

//----------------------------------------------------------------------------//
// Pagina para entrada de dados: Transação de Deposito/Saque.
//----------------------------------------------------------------------------//
User Function ASP5()

Local cHtml := ""

WEB EXTENDED INIT cHtml

Prepare Environment Empresa "99" Filial "01" Modulo "ESP" Tables "SZ1", "SZ2"

cHtml += ExecInPage("275_ASP5")

WEB EXTENDED END

Return cHtml

//----------------------------------------------------------------------------//
// Função chamada pelo botão Enviar do 275_ASP5.APH
//----------------------------------------------------------------------------//
User Function ASP5Grava()

Local cHtml := ""

WEB EXTENDED INIT cHtml

// Validações:

If      HttpPost->cboNome == "Selecione um nome"

        cHtml := "O nome não foi selecionado!"
        cHtml += "<p><input type='button' name='Button' value='Voltar' onclick='javaScript:history.back()'>"

 ElseIf Empty(CtoD(HttpPost->Data))

        cHtml := "Digite um data correta!"
        cHtml += "<p><input type='button' name='Button' value='Voltar' onclick='javaScript:history.back()'>"

 ElseIf Val(HttpPost->Valor) == 0
 
        cHtml := "Digite um valor!"
        cHtml += "<p><input type='button' name='Button' value='Voltar' onclick='javaScript:history.back()'>"

 Else

        Prepare Environment Empresa "99" Filial "01" Modulo "ESP" Tables "SZ1", "SZ2"

        dbSelectArea("SZ2")
        RecLock("SZ2", .T.)
        SZ2->Z2_Filial := xFilial("SZ2")
        SZ2->Z2_Nome   := HttpPost->cboNome
        SZ2->Z2_Numero := GetSXENum("SZ2", "Z2_NUMERO")
        SZ2->Z2_Item   := "01"
        SZ2->Z2_Data   := CtoD(HttpPost->Data)
        SZ2->Z2_Tipo   := HttpPost->Tipo
        SZ2->Z2_Hist   := HttpPost->Hist
        SZ2->Z2_Valor  := Val(HttpPost->Valor)
        MSUnlock()

        ConfirmSX8()

        // Atualiza o saldo.
        dbSelectArea("SZ1")
        dbOrderNickName("NOME")
        dbSeek(xFilial("SZ1") + SZ2->Z2_Nome)
        RecLock("SZ1", .F.)
        If SZ2->Z2_Tipo = "D"
           SZ1->Z1_Saldo := SZ1->Z1_Saldo + SZ2->Z2_Valor
         Else
           SZ1->Z1_Saldo := SZ1->Z1_Saldo - SZ2->Z2_Valor
        EndIf
        MSUnLock()

        cHtml := "Transação gravada com sucesso!"

EndIf

WEB EXTENDED END

Return cHtml
