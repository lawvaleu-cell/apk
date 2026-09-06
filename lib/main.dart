import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdfrx/pdfrx.dart';

const String apiBase = 'https://server-5xab.onrender.com';
const String publicBase = 'https://ra9mana-dz.github.io/ra9mana-dz-pro';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDb.open();
  runApp(Ra9manaApp(db: db));
}

class Ra9manaApp extends StatelessWidget {
  final AppDb db;
  const Ra9manaApp({super.key, required this.db});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'RA9MANA DZ',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF2563EB), fontFamily: 'sans'),
    home: HomePage(db: db),
  );
}

class AppDb {
  final Database db;
  AppDb._(this.db);
  static Future<AppDb> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final database = await openDatabase(p.join(dir.path, 'ra9mana.db'), version: 1,
      onCreate: (db, v) async {
        await db.execute('CREATE TABLE refs (id TEXT PRIMARY KEY, title TEXT, author TEXT, type TEXT, category TEXT, year TEXT, language TEXT, country TEXT, university TEXT, description TEXT, keywords TEXT, source TEXT, externalLink TEXT, notes TEXT, status TEXT, submitted_at TEXT, pdf TEXT, cover TEXT)');
      });
    return AppDb._(database);
  }
  Future<List<Map<String,dynamic>>> all() => db.query('refs', orderBy: 'year DESC, title ASC');
  Future<void> upsert(Map<String,dynamic> x) async {
    final allowed = {'id':x['id'],'title':x['title']??'','author':x['author']??'','type':x['type']??'','category':x['category']??'','year':x['year']??'','language':x['language']??'','country':x['country']??'','university':x['university']??'','description':x['description']??'','keywords':x['keywords']??'','source':x['source']??'','externalLink':x['externalLink']??'','notes':x['notes']??'','status':x['status']??'published','submitted_at':x['submitted_at']??'','pdf':x['pdf']??'','cover':x['cover']??''};
    await db.insert('refs', allowed, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

class SyncService {
  final AppDb db;
  SyncService(this.db);
  Future<int> sync() async {
    final uri = Uri.parse('$apiBase/api/references');
    final res = await http.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final decoded = jsonDecode(res.body);
    final list = decoded is List ? decoded : (decoded['references'] ?? []);
    int count = 0;
    for (final item in list) {
      final m = Map<String,dynamic>.from(item);
      if ((m['status'] ?? 'published') == 'published') { await db.upsert(m); count++; }
    }
    return count;
  }
}

class HomePage extends StatefulWidget {
  final AppDb db;
  const HomePage({super.key, required this.db});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  List<Map<String,dynamic>> refs=[]; bool syncing=false; String q='';
  @override void initState(){super.initState(); load(); syncSilently();}
  Future<void> load() async { final x=await widget.db.all(); if(mounted)setState(()=>refs=x); }
  Future<void> syncSilently() async { try { setState(()=>syncing=true); await SyncService(widget.db).sync(); await load(); } catch (_) {} finally { if(mounted)setState(()=>syncing=false); } }
  List<Map<String,dynamic>> get filtered => refs.where((r){final s=q.toLowerCase(); return s.isEmpty || '${r['title']} ${r['author']} ${r['category']} ${r['keywords']}'.toLowerCase().contains(s);}).toList();
  @override Widget build(BuildContext context)=>Scaffold(
    appBar: AppBar(title: const Text('RA9MANA DZ',style:TextStyle(fontWeight:FontWeight.w800)), actions:[IconButton(onPressed:syncing?null:syncSilently,icon:Icon(syncing?Icons.sync:Icons.sync_outlined))]),
    body: Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,12,16,8),child:TextField(onChanged:(v)=>setState(()=>q=v),decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:'Rechercher une référence...',border:OutlineInputBorder(borderRadius:BorderRadius.circular(16))))),
      Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:6),child:Row(children:[const Icon(Icons.cloud_done_outlined,size:18),const SizedBox(width:7),Text('${refs.length} références disponibles hors ligne'),const Spacer(),if(syncing)const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2))])),
      Expanded(child: filtered.isEmpty ? const Center(child:Text('Aucune référence trouvée')) : ListView.builder(itemCount:filtered.length,itemBuilder:(c,i)=>ReferenceCard(ref:filtered[i],db:widget.db)))
    ]));
}

class ReferenceCard extends StatelessWidget {
  final Map<String,dynamic> ref; final AppDb db;
  const ReferenceCard({super.key,required this.ref,required this.db});
  @override Widget build(BuildContext context)=>Card(margin:const EdgeInsets.fromLTRB(16,6,16,6),child:InkWell(borderRadius:BorderRadius.circular(16),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ReferencePage(ref:ref,db:db))),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:Theme.of(context).colorScheme.primaryContainer,borderRadius:BorderRadius.circular(20)),child:Text(ref['type']??'reference')),const Spacer(),Text(ref['year']??'')]),
    const SizedBox(height:8), Text(ref['title']??'',style:const TextStyle(fontSize:17,fontWeight:FontWeight.w750)),
    const SizedBox(height:6),Text('${ref['category']??''} • ${ref['country']??''}',style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant)),
    if((ref['description']??'').toString().isNotEmpty) ...[const SizedBox(height:6),Text(ref['description'],maxLines:2,overflow:TextOverflow.ellipsis)]
  ]))));
}

class ReferencePage extends StatefulWidget { final Map<String,dynamic> ref; final AppDb db; const ReferencePage({super.key,required this.ref,required this.db}); @override State<ReferencePage> createState()=>_ReferencePageState(); }
class _ReferencePageState extends State<ReferencePage>{ bool downloading=false; String? localPath;
  Future<File> ensurePdf() async { final docs=await getApplicationDocumentsDirectory(); final dir=Directory(p.join(docs.path,'pdfs')); await dir.create(recursive:true); final path=p.join(dir.path,'${widget.ref['id']}.pdf'); final f=File(path); if(await f.exists())return f; setState(()=>downloading=true); final rel=(widget.ref['pdf']??'').toString(); final url=rel.startsWith('http')?rel:'$publicBase/$rel'; final r=await http.get(Uri.parse(url)).timeout(const Duration(seconds:60)); if(r.statusCode!=200)throw Exception('PDF HTTP ${r.statusCode}'); await f.writeAsBytes(r.bodyBytes); return f; }
  Future<void> openPdf() async { try { final f=await ensurePdf(); if(mounted)Navigator.push(context,MaterialPageRoute(builder:(_)=>PdfPage(path:f.path,title:widget.ref['title']??''))); } catch(e){ if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر فتح المرجع: $e'))); } finally { if(mounted)setState(()=>downloading=false); } }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('تفاصيل المرجع')),body:ListView(padding:const EdgeInsets.all(20),children:[Text(widget.ref['title']??'',style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800)),const SizedBox(height:12),Wrap(spacing:8,runSpacing:8,children:[Chip(label:Text(widget.ref['year']??'')),Chip(label:Text(widget.ref['category']??'')),Chip(label:Text(widget.ref['language']??''))]),const SizedBox(height:18),if((widget.ref['description']??'').toString().isNotEmpty)Text(widget.ref['description'],style:const TextStyle(fontSize:16,height:1.5)),const SizedBox(height:24),FilledButton.icon(onPressed:downloading?null:openPdf,icon:Icon(downloading?Icons.downloading:Icons.picture_as_pdf),label:Text(downloading?'جارٍ تحميل المرجع...':'فتح المرجع')),if((widget.ref['externalLink']??'').toString().isNotEmpty)TextButton.icon(onPressed:()=>launchUrl(Uri.parse(widget.ref['externalLink']),mode:LaunchMode.externalApplication),icon:const Icon(Icons.open_in_new),label:const Text('المصدر الخارجي'))]));
}
class PdfPage extends StatelessWidget {final String path,title;const PdfPage({super.key,required this.path,required this.title}); @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(title,maxLines:1,overflow:TextOverflow.ellipsis)),body:PdfViewer.file(path));}
