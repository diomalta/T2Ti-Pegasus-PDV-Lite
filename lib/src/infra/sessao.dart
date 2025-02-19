/*
Title: T2Ti ERP 3.0                                                                
Description: Armazena os objetos para a sessão
                                                                                
The MIT License                                                                 
                                                                                
Copyright: Copyright (C) 2021 T2Ti.COM                                          
                                                                                
Permission is hereby granted, free of charge, to any person                     
obtaining a copy of this software and associated documentation                  
files (the "Software"), to deal in the Software without                         
restriction, including without limitation the rights to use,                    
copy, modify, merge, publish, distribute, sublicense, and/or sell               
copies of the Software, and to permit persons to whom the                       
Software is furnished to do so, subject to the following                        
conditions:                                                                     
                                                                                
The above copyright notice and this permission notice shall be                  
included in all copies or substantial portions of the Software.                 
                                                                                
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,                 
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES                 
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND                        
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT                     
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,                    
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING                    
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR                   
OTHER DEALINGS IN THE SOFTWARE.                                                 
                                                                                
       The author may be contacted at:                                          
           t2ti.com@gmail.com                                                   
                                                                                
@author Albert Eije (alberteije@gmail.com)                    
@version 1.0.0
*******************************************************************************/
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:pegasus_pdv/src/infra/biblioteca.dart';

import 'package:pegasus_pdv/src/model/retorno_json_erro.dart';
import 'package:pegasus_pdv/src/model/filtro.dart';

import 'package:pegasus_pdv/src/database/database.dart';
import 'package:pegasus_pdv/src/database/database_classes.dart';

import 'constantes.dart';

class Sessao {
  /// singleton
  factory Sessao() {
    _this ??= Sessao._();
    return _this;
  }
  static Sessao _this;
  Sessao._() : super();


// #region objetos globais
  static Filtro filtroGlobal = Filtro();
  static String tokenJWT = '';

  // objetos PDV
  static AppDatabase db;

  static var statusCaixa; 

  static PdvMovimento movimento;
  static Empresa empresa;
  static PdvConfiguracao configuracao = PdvConfiguracao(id: null);
  static PdvVendaCabecalho vendaAtual = PdvVendaCabecalho(id: null);
  static List<VendaDetalhe> listaVendaAtualDetalhe = [];
  static List<PdvTipoPagamento> listaTipoPagamento = [];
  static List<PdvTotalTipoPagamento> listaDadosPagamento = [];
  static String retornoJsonLookup; // será usado para popular a grid da janela de lookup
  static RetornoJsonErro objetoJsonErro;

// #endregion objetos globais

  /// popula os objetos principais para a sessão
  static Future popularObjetosPrincipais(BuildContext context) async {
    db = Provider.of<AppDatabase>(context, listen: false);
    if (movimento == null) {
      await tratarMovimento();
    }    
    empresa = await db.empresaDao.consultarObjeto(1); // pega a empresa - deve ter apenas um registro no banco de dados
    // se o logo estiver nulo, insere um logo padrão e o usuário poderá alterar depois na tela de cadastro da empresa
    if (empresa.logotipo == null) {
      final logotipo = (await rootBundle.load('assets/images/sua_logo.png')).buffer.asUint8List();
      empresa = empresa.copyWith(
        logotipo: logotipo,
      );
      await db.empresaDao.alterar(Sessao.empresa);
    }
    configuracao = await db.pdvConfiguracaoDao.consultarObjeto(1); // pega a configuracao - deve ter apenas um registro no banco de dados
    listaTipoPagamento = await db.pdvTipoPagamentoDao.consultarLista(); // pega os tipos de pagamento e poe numa lista

    if (kDebugMode && Biblioteca.isDesktop()) {
      await _gerarArquivoEnvProtegido();  
    }
  }

  /// Passos:
  /// 01-busca um movimento com status = 'A' (aberto)
  /// 02-se não existir movimento, abre
  /// 03-se existir um movimento
  /// 03.1-verifica se o movimento é de outro dia
  /// 03.1.1 - se for um movimento de outro dia, encerra movimento e abre outro
  /// 03.1.2 - se for um movimento do mesmo dia, atribui para o movimento da sessão 
  static Future<void> tratarMovimento() async {
    movimento = await db.pdvMovimentoDao.consultarObjeto('A'); 
    if (movimento == null) {
      movimento = PdvMovimento(id: null, dataAbertura: DateTime.now(), horaAbertura: Biblioteca.horaFormatada(DateTime.now()), statusMovimento: 'A');
      movimento = await db.pdvMovimentoDao.iniciarMovimento(movimento);
    } else {
      if (Biblioteca.dataFormatada(movimento.dataAbertura) != Biblioteca.dataFormatada(DateTime.now())) {
        await db.pdvMovimentoDao.encerrarMovimento(movimento);
        movimento = PdvMovimento(id: null, dataAbertura: DateTime.now(), horaAbertura: Biblioteca.horaFormatada(DateTime.now()), statusMovimento: 'A');
        movimento = await db.pdvMovimentoDao.iniciarMovimento(movimento);
      }
    }
  }

  static Future<void> _gerarArquivoEnvProtegido() async {
    var conteudoEnvProtegido = '';

    conteudoEnvProtegido += 'SENTRY_DNS=' + Constantes.encrypter.encrypt(Constantes.sentryDns, iv: Constantes.iv).base64 + '\n';
    conteudoEnvProtegido += 'LINGUAGEM_SERVIDOR=' + Constantes.encrypter.encrypt(Constantes.linguagemServidor, iv: Constantes.iv).base64 + '\n';
    conteudoEnvProtegido += 'ENDERECO_SERVIDOR=' + Constantes.encrypter.encrypt(Constantes.enderecoServidor, iv: Constantes.iv).base64 + '\n';
    conteudoEnvProtegido += 'COMPLEMENTO_ENDERECO_SERVIDOR=' + Constantes.encrypter.encrypt(Constantes.complementoEnderecoServidor, iv: Constantes.iv).base64 + '\n';
    conteudoEnvProtegido += 'PORTA_SERVIDOR=' + Constantes.encrypter.encrypt(Constantes.portaServidor, iv: Constantes.iv).base64;

    final File file = File('.env-cifrado');
    await file.writeAsString(conteudoEnvProtegido);
  }

}