#Include "PROTHEUS.CH"
#Include "RWMAKE.CH"
#Include "TOPCONN.CH"

//----------------------------------------------------------------------------//
// Demostracao da leitura sequencial de um arquivo com indice e filtro especifico.
//----------------------------------------------------------------------------//
User Function DBFSQL1()

Local cQuery
Local cArqInd
Local cChave
Local cFiltro
Local cOrdem
Local lMostra

#IfDef TOP    // Base de dados SQL.

   // Define a query. A funcao RetSqlName() retorna o nome fisico do arquivo: SZ2990
   cQuery := "SELECT * FROM " + RetSqlName("SZ2") + " "
   cQuery += "WHERE Z2_FILIAL = '" + xFilial("SZ2") + "' AND Z2_TIPO = 'S' AND D_E_L_E_T_ <> '*' "
   cQuery += "ORDER BY Z2_NOME, Z2_DATA"

   // Compatibiliza a query para o banco de dados em uso.
   cQuery := ChangeQuery(cQuery)

   // Executa a query e retorna uma WorkArea denominada MOVIM, contendo os registros
   // filtrados pela clausula WHERE e em ordem de Nome+Data.
   TCQuery cQuery Alias MOVIM New //Via "TOPCONN"

   // Converte os campos tipo Data, Numerico e Logico para os tipos corretos definidos no SX3.
   TCSetField("MOVIM", "Z2_DATA", "D")
   TCSetField("MOVIM", "Z2_VALOR", "N", 12, 2)

   dbSelectArea("MOVIM")
   While !MOVIM->(Eof())
      MsgAlert(MOVIM->Z2_Nome + " " + MOVIM->Z2_Tipo + " " + DtoC(MOVIM->Z2_Data) + " " + Str(MOVIM->Z2_Valor))
      MOVIM->(dbSkip())
   End

   dbSelectArea("MOVIM")
   dbCloseArea()

 #Else        // Base de dados DBF ou CTree.

   dbSelectArea("SZ2")
   cArqInd := CriaTrab(Nil, .F.)                                  // Nome do arq.temporario.
   cChave  := "xFilial('SZ2') + Z2_Nome + DtoS(Z2_Data)"          // Chave de indexacao.
   cFiltro := "Z2_Filial == xFilial('SZ2') .And. Z2_Tipo == 'S'"  // Filtro.
   cOrdem  := " "                                                 // "D" = decrescente.
   lMostra := .T.                                                 // Mostrar a regua de progressao.

   // Cria um indice temporario ja filtrado.
   IndRegua("SZ2", cArqInd, cChave, cOrdem, cFiltro, "Indexando...", lMostra)

   While !SZ2->(Eof())
      MsgAlert(SZ2->Z2_Nome + " " + SZ2->Z2_Tipo + " " + DtoC(SZ2->Z2_Data) + " " + Str(SZ2->Z2_Valor))
      SZ2->(dbSkip())
   End

   RetIndex("SZ2")                // Reativa os indices originais que foram desativados pelo IndRegua().

   FErase(cArqInd + OrdBagExt())  // Deleta o arq. criado para liberar espaco em disco.

#EndIf

Return

//----------------------------------------------------------------------------//
// Demostracao de acesso direto à base de dados.
// Em bases de dados SQL, o acesso a um unico registro é executado tambem por
// meio de uma query, enquanto que em arquivos DBF é pelo comando dbSeek(), que
// posiciona direto no registro, pela chave.
//----------------------------------------------------------------------------//
User Function DBFSQL2()

Local oDlg
Local cNome := Space(Len(SZ1->Z1_Nome))
Local oSaldo
Local nSaldo := 0

Define MSDialog oDlg Title "Acesso à Base Dados" From 0,0 To 200,250 Pixel

@30,10 Say "Nome:" Pixel Of oDlg
@30,50 MSGet oNome Var cNome Picture "@!" Size 50,10 Pixel F3 "SZ1" Valid u_VeSaldo(cNome, oSaldo, @nSaldo) Of oDlg

@50,10 Say "Saldo:" Pixel Of oDlg
@50,50 Get oSaldo Var nSaldo Picture "@E 999,999,999.99" Size 50,10 Pixel Of oDlg

Activate MSDialog oDlg Centered

Return

//----------------------------------------------------------------------------//
User Function VeSaldo(cNome, oSaldo, nSaldo)

Local cQuery

#IfDef TOP    // Base de dados SQL.

   // Define a query. A funcao RetSqlName() retorna o nome fisico do arquivo: SZ2990
   cQuery := "SELECT Z1_SALDO FROM " + RetSqlName("SZ1") + " "
   cQuery += "WHERE Z1_FILIAL = '" + xFilial("SZ1") + "' AND Z1_NOME = '" + cNome + "' AND D_E_L_E_T_ <> '*'"
   
   // Executa a query e retorna uma WorkArea denominada MOVIM, contendo os registros
   // filtrados pela clausula WHERE.
   TCQuery cQuery Alias SALDO New

   // Converte os campos para os tipos corretos definidos no SX3.
   TCSetField("SALDO", "Z1_Saldo", "N", 12, 2)
   
   dbSelectArea("SALDO")

   nSaldo := SALDO->Z1_Saldo

   // Fecha a WorkArea criada pela query.
   dbSelectArea("SALDO")
   dbCloseArea()

 #Else        // Base de dados DBF ou CTree.

   dbSelectArea("SZ1")
   dbOrderNickName("NOME")
   dbSeek(xFilial("SZ1") + cNome)
   nSaldo := SZ1->Z1_Saldo

#EndIf

// Atualiza o conteudo do campo de saldo na tela.
oSaldo:SetText(nSaldo)
oSaldo:Refresh()

Return .T.

//----------------------------------------------------------------------------//
// Demonstracao de atualizacao (UPDATE) da base de dados.
//----------------------------------------------------------------------------//
User Function DBFSQL3()

Local oDlg, oBtnOk, oBtnCancel
Local nPct := 0

Define MSDialog oDlg Title "Atualização da Base Dados" From 0,0 To 200,450 Pixel

@50,010 Say "% Limite de cheque-especial:" Pixel Of oDlg
@50,150 Get nPct Size 50,10 Picture "@E 999" Pixel Of oDlg

@oDlg:nHeight/2-30,oDlg:nClientWidth/2-70 Button oBtnOk     Prompt "&Ok"       Size 30,15 Pixel Action u_Calcula(nPct) Of oDlg
@oDlg:nHeight/2-30,oDlg:nClientWidth/2-35 Button oBtnCancel Prompt "&Cancelar" Size 30,15 Pixel Action oDlg:End()      Of oDlg

Activate MSDialog oDlg Centered

Return

//----------------------------------------------------------------------------//
User Function Calcula(nPct)

#IfDef TOP

   TCSQLExec("UPDATE SZ1990 SET Z1_LIMITE = Z1_SALDO * " + Str((1+(nPct/100))))

 #Else

   dbSelectArea("SZ1")
   dbOrderNickName("NOME")
   dbGoTop()

   While !SZ1->(Eof())

      RecLock("SZ1")
      SZ1->Z1_Limite := SZ1->Z1_Saldo * (1+(nPct/100))
      MSUnlock()
      SZ1->(dbSkip())

   End

#EndIf

MsgAlert("OK")

Return

//----------------------------------------------------------------------------//
// Demostracao de campos agregados.
//----------------------------------------------------------------------------//
User Function DBFSQL4()

Local cQuery

#IfDef TOP    // Base de dados SQL.

   // Define a query. A funcao RetSqlName() retorna o nome fisico do arquivo: SZ2990
   cQuery := "SELECT Z2_NUMERO, Z2_VALOR, Z2_VALOR*2 AS VALOR2, Z2_VALOR*3 AS VALOR3 FROM " + RetSqlName("SZ2") + " "
   cQuery += "WHERE Z2_FILIAL = '" + xFilial("SZ2") + "' AND D_E_L_E_T_ <> '*'"

   // Executa a query e retorna uma WorkArea denominada MOVIM, contendo os registros
   // filtrados pela clausula WHERE.
   TCQuery cQuery Alias MOVIM New //Via "TOPCONN"

   dbSelectArea("MOVIM")
   While !MOVIM->(Eof())
      // Colunas agregadas: caso nao seja especificado um alias para as colunas agregadas, recebem o nome de cFieldN,
      // onde N é a posicao da coluna dentro da query.
      // MsgAlert(MOVIM->Z2_Numero + " " + Str(MOVIM->Z2_Valor) + " " + Str(MOVIM->cField3) + " " + Str(MOVIM->cField4))
      MsgAlert(MOVIM->Z2_Numero + " " + Str(MOVIM->Z2_Valor) + " " + Str(MOVIM->Valor2) + " " + Str(MOVIM->Valor3))
      MOVIM->(dbSkip())
   End

#EndIf

Return

//----------------------------------------------------------------------------//
// Demostracao do PACK - exclusao dos registros deletados.
//----------------------------------------------------------------------------//
User Function DBFSQL5()

#IfDef TOP

   TCSQLExec("DELETE " + RetSqlName("SZ2") + " WHERE D_E_L_E_T_ = '*'")

   MsgAlert("OK: SQL/DELETE")

 #Else

   AbreExcl("SZ2")
   Pack

   MsgAlert("OK: DBF/PACK")

#EndIf

Return

//----------------------------------------------------------------------------//
// Demonstracao do Embedded SQL, que permite escrever diretamente os comandos
// SQL, sem a necessidade de montar uma string e executar via TCQuery.
//----------------------------------------------------------------------------//
User Function DBFSQL6()

Local cTipo

/* Modelo usando string e TCQuery:

cQuery := "SELECT * FROM " + RetSqlName("SZ2") + " "
cQuery += "WHERE Z2_FILIAL = '" + xFilial("SZ2") + "' AND Z2_TIPO = 'S' AND D_E_L_E_T_ <> '*' "
cQuery += "ORDER BY Z2_NOME, Z2_DATA"

cQuery := ChangeQuery(cQuery)

TCQuery cQuery Alias MOVIM New //Via "TOPCONN"

TCSetField("MOVIM", "Z2_DATA", "D")
TCSetField("MOVIM", "Z2_VALOR", "N", 12, 2)

*/

#IfDef TOP    // Base de dados SQL.

   // Modelo usando Embedded SQL:
   //   Column     --> equivale à funcao TCSetField()
   //   %NoParser% --> nao submete a query à funcao ChangeQuery()
   //   %Table%    --> equivale à funcao RetSqlName()
   //   %xFilial%  --> equivale à funcao xFilial()
   //   %NotDel%   --> equivale à D_E_L_E_T_= ' '
   //   %Order%    --> equivale à funcao SqlOrder()
   //   %exp%      --> variaveis e expressoes

   // Nao poderao existir chamadas de funcoes dentro de BeginSQL...EndSQL; somente variaveis.
   cTipo := u_Tipo()

   BeginSQL Alias "MOVIM"

      Column Z2_DATA  As Date
      Column Z2_VALOR As Numeric(12,2)

      %NoParser%

      SELECT SZ2.Z2_NOME, SZ2.Z2_TIPO, SZ2.Z2_DATA, SZ2.Z2_VALOR
      FROM %Table:SZ2% SZ2
      WHERE SZ2.Z2_FILIAL = %xFilial:SZ2% AND SZ2.Z2_TIPO = %exp:cTipo% AND SZ2.%NotDel%
      ORDER BY %Order:SZ2,1%

   EndSQL

   dbSelectArea("MOVIM")
   While !MOVIM->(Eof())
      MsgAlert(MOVIM->Z2_Nome + " " + MOVIM->Z2_Tipo + " " + DtoC(MOVIM->Z2_Data) + " " + Str(MOVIM->Z2_Valor,12,2))
      MOVIM->(dbSkip())
   End

   dbSelectArea("MOVIM")
   dbCloseArea()

#EndIf

Return
