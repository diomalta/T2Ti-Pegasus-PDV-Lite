/*
Title: T2Ti ERP Pegasus                                                                
Description: DAO relacionado à tabela [PDV_MOVIMENTO] 
                                                                                
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
import 'package:moor/moor.dart';

import 'package:pegasus_pdv/src/database/database.dart';
import 'package:pegasus_pdv/src/database/database_classes.dart';
import 'package:pegasus_pdv/src/infra/biblioteca.dart';

part 'pdv_movimento_dao.g.dart';

@UseDao(tables: [
          PdvMovimentos,
          PdvFechamentos,
		])
class PdvMovimentoDao extends DatabaseAccessor<AppDatabase> with _$PdvMovimentoDaoMixin {
  final AppDatabase db;

  PdvMovimentoDao(this.db) : super(db);

  Future<List<PdvMovimento>> consultarLista() => select(pdvMovimentos).get();

  Future<List<PdvMovimento>> consultarListaFiltro(String campo, String valor) async {
    return (customSelect("SELECT * FROM PDV_MOVIMENTO WHERE " + campo + " like '%" + valor + "%'", 
                                readsFrom: { pdvMovimentos }).map((row) {
                                  return PdvMovimento.fromData(row.data, db);  
                                }).get());
  }

  Stream<List<PdvMovimento>> observarLista() => select(pdvMovimentos).watch();

  Future<PdvMovimento> consultarObjeto(String pStatus) {
    return (select(pdvMovimentos)..where((t) => t.statusMovimento.equals(pStatus))).getSingleOrNull();
  } 

  Future<int> inserir(Insertable<PdvMovimento> pObjeto) {
    return transaction(() async {
      final idInserido = await into(pdvMovimentos).insert(pObjeto);
      return idInserido;
    });    
  } 

  Future<bool> alterar(Insertable<PdvMovimento> pObjeto) {
    return transaction(() async {
      return update(pdvMovimentos).replace(pObjeto);
    });    
  } 

  Future<int> excluir(Insertable<PdvMovimento> pObjeto) {
    return transaction(() async {
      return delete(pdvMovimentos).delete(pObjeto);
    });    
  }

  Future<PdvMovimento> iniciarMovimento(Insertable<PdvMovimento> pObjeto) {
    return transaction(() async {
      await into(pdvMovimentos).insert(pObjeto);
      return await db.pdvMovimentoDao.consultarObjeto('A');
    });    
  } 

  Future<void> encerrarMovimento(PdvMovimento pObjeto, {List<PdvFechamento> listaFechamento}) {
    return transaction(() async {
      PdvVendaCabecalho totaisVenda = await db.pdvVendaCabecalhoDao.consultarTotaisDia(pObjeto.id);
      PdvSuprimento totaisSuprimento = await db.pdvSuprimentoDao.consultarTotaisDia(pObjeto.id);
      PdvSangria totaisSangria = await db.pdvSangriaDao.consultarTotaisDia(pObjeto.id);
      pObjeto = 
      pObjeto.copyWith(
        statusMovimento: 'F',
        dataFechamento: DateTime.now(),
        horaFechamento: Biblioteca.horaFormatada(DateTime.now()),        
        totalSuprimento: totaisSuprimento.valor,
        totalSangria: totaisSangria.valor,
        totalVenda: totaisVenda.valorVenda,
        totalDesconto: totaisVenda.valorDesconto,
        totalFinal: totaisVenda.valorFinal,
        totalRecebido: totaisVenda.valorRecebido,
        totalTroco: totaisVenda.valorTroco,
        totalCancelado: totaisVenda.valorCancelado,
      ); 
      await alterar(pObjeto);
      // pagamentos
      if (listaFechamento != null) {
        for (var objeto in listaFechamento) {
          into(pdvFechamentos).insert(objeto);  
        }
      }
    });    
  } 

}