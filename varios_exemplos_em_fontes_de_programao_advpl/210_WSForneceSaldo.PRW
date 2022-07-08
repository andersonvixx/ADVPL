#INCLUDE "PROTHEUS.CH"
#INCLUDE "APWEBSRV.CH"         

//----------------------------------------------------------------------------//
// Informa o saldo.
//----------------------------------------------------------------------------//
WsService ForneceSaldo Description "Fornece o saldo de uma conta."

   WsData Nome       As String
   WsData Saldo      As Float
   WsData Transacoes As Array Of String

   WsMethod BuscaSaldo      Description "Busca o saldo da conta."
   WsMethod BuscaTransacoes Description "Busca as contas e as suas transacoes."

EndWsService

WsMethod BuscaSaldo WsReceive Nome WsSend Saldo WsService ForneceSaldo

   ::Saldo := 0

   dbSelectArea("SZ1")
   dbOrderNickName("NOME")

   If dbSeek(xFilial() + Nome)
      ::Saldo := SZ1->Z1_Saldo
   EndIf

Return .T.

WsMethod BuscaTransacoes WsReceive NULLPARAM WsSend Transacoes WsService ForneceSaldo

   ::Transacoes := {}

   dbSelectArea("SZ1")
   dbOrderNickName("NOME")
   dbSeek(xFilial("SZ1"))

   // Le o cadastro de contas.
   While SZ1->Z1_Filial == xFilial("SZ1") .And. !SZ1->(Eof())

      AAdd(::Transacoes, "SZ1" + SZ1->Z1_Nome)

      dbSelectArea("SZ2")
      dbOrderNickName("NOME_NR_IT")
      dbSeek(xFilial("SZ2") + SZ1->Z1_Nome)

      // Para cada conta, le as respectivas transacoes.
      While SZ2->Z2_Filial + SZ2->Z2_Nome == xFilial("SZ2") + SZ1->Z1_Nome .And. !SZ2->(Eof())
         AAdd(::Transacoes, "SZ2" + DtoC(SZ2->Z2_Data) + SZ2->Z2_Tipo + Transform(SZ2->Z2_Valor, "@E 999,999,999.99"))
         SZ2->(dbSkip())
      End

      SZ1->(dbSkip())

   End

Return .T.
