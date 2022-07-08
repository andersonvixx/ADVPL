//----------------------------------------------------------------------------------------------------------------// 
// Apos uma transacao, caso o saldo fique negativo, envia um WorkFlow para o aprovador.
// Ele pode aprovar ou nao esta transacao. A resposta (SIM ou NAO), sera gravada no campo Z2_APROV.
//----------------------------------------------------------------------------------------------------------------// 
User Function WFSalNeg(cNome, cEMail, cNumero, cItem, dData, cHist, nValor, nSaldo)

Local oWF

// Inicializa a classe TWFProcess (WorkFlow).
oWF := TWFProcess():New( "APROVA", "Aprovação do Lançamento" )

// Cria uma nova tarefa para o processo.
oWF:NewTask( "Aprovacao", "\workflow\190_WFSalNeg.htm" )

// Preenche as variaveis no html.
oWF:oHtml:ValByName("NOME"  , cNome  )
oWF:oHtml:ValByName("SALDO" , nSaldo )
oWF:oHtml:ValByName("NUMERO", cNumero)
oWF:oHtml:ValByName("ITEM"  , cItem  )
oWF:oHtml:ValByName("DATA"  , dData  )
oWF:oHtml:ValByName("HIST"  , cHist  )
oWF:oHtml:ValByName("VALOR" , nValor )

// Destinatário do WorkFlow.
oWF:cTo := cEMail

// Assunto da mensagem.
oWF:cSubject := "Aprovação do Lançamento"

// Função a ser executada quando a resposta chegar.
oWF:bReturn  := "U_WFRetorno"

// Função a ser executada quando expirar o tempo do TimeOut.
// Tempos limite de espera das respostas, em dias, horas e minutos.
oWF:bTimeOut := {{"U_WFTmOut",0,0,10}}

// Gera os arquivos de controle deste processo e envia a mensagem.
oWF:Start() 

MsgAlert("SALDO NEGATIVO: Enviado WorkFlow para o Aprovador.")

Return

//----------------------------------------------------------------------------------------------------------------// 
User Function WFRetorno(oWF)

Local cNumero
Local cItem
Local cAprova

cNumero := oWF:oHtml:RetByName("NUMERO")         // Obtem o Nr.da Transacao.
cItem   := oWF:oHtml:RetByName("ITEM")           // Obtem o Nr.do Item.
cAprova := oWF:oHtml:RetByName("APROVA")         // Obtem a resposta do Aprovador.

dbSelectArea("SZ2")                              // Seleciona o arquivo de Transacoes.
dbOrderNickName("NR_IT")                         // Seleciona a chave primaria.
dbSeek(xFilial() + cNumero + cItem)              // Procura a transacao.
RecLock("SZ2")                                   // Bloqueia o registro.
SZ2->Z2_Aprov := cAprova                         // Grava a resposta do Aprovador.
MSUnlock()                                       // Desbloqueia o registro.

// Finaliza o processo.
oWF:Finish()

Return

//----------------------------------------------------------------------------------------------------------------// 
User Function WFTmOut(oWF)

// Faz um reenvio da mensagem... Neste instante, é possivel mudar o
// endereço do destinatário.
oWF:cSubject += " (Timeout processo: " + oWF:fProcessID + ") REENVIO" 

// Reenvia a mensagem.
oWF:Start()

Return
