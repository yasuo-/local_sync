import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:local_sync/pages/pdf_detail_page.dart';
import 'package:local_sync/widgets/pdf_thumbnail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PDFViewersScreen extends StatefulWidget {
  const PDFViewersScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PDFViewersScreenState createState() => _PDFViewersScreenState();
}

class _PDFViewersScreenState extends State<PDFViewersScreen> {
  String? _folderPath;
  List<String> _pdfFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFolderPath();
  }

  // フォルダパスを保存
  Future<void> _saveFolderPath(String path) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('folderPath', path);
  }

  // 保存されたフォルダパスをロード
  Future<void> _loadFolderPath() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? path = prefs.getString('folderPath');
    if (path != null) {
      final directory = Directory(path);
      if (await directory.exists()) {
        setState(() {
          _folderPath = path;
          _isLoading = true;
        });
        _getPDFFilesFromFolder(path);
        _watchFolder(path);
      } else {
        _requestFolderAccess();
      }
    } else {
      _requestFolderAccess();
    }
  }

  // フォルダへのアクセス権限を取得
  void _requestFolderAccess() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'PDFファイルが含まれるフォルダを選択してください',
    );

    if (selectedDirectory != null) {
      // ユーザーがフォルダを選択した場合
      setState(() {
        _folderPath = selectedDirectory;
        _isLoading = true;
      });

      await _saveFolderPath(selectedDirectory);
      _getPDFFilesFromFolder(selectedDirectory);
      _watchFolder(selectedDirectory);
    } else {
      // ユーザーがキャンセルした場合
      // TODO:: 適切な処理を追加する
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('フォルダが選択されていません。アプリを終了します。')),
      );
      Future.delayed(const Duration(seconds: 2), () {
        exit(0);
      });
    }
  }

  // フォルダ内のPDFファイルを取得
  Future<void> _getPDFFilesFromFolder(String folderPath) async {
    final directory = Directory(folderPath);
    List<String> pdfFiles = [];

    if (await directory.exists()) {
      try {
        // 非同期ストリームを使用してディレクトリをリストアップ
        await for (var entity
            in directory.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            // ファイルの拡張子をチェック
            if (entity.path.toLowerCase().endsWith('.pdf')) {
              pdfFiles.add(entity.path);
            }
          }
        }
      } on FileSystemException catch (e) {
        // ディレクトリリスティング時のファイルシステム例外をキャッチ
        print('ディレクトリのリスティングに失敗しました: $folderPath, エラー: $e');
      } catch (e) {
        // その他の例外をキャッチ
        print('予期しないエラーが発生しました: $e');
      }
    } else {
      print('指定されたディレクトリが存在しません: $folderPath');
    }

    setState(() {
      _pdfFiles = pdfFiles;
      _isLoading = false; // スキャン完了
    });
  }

  // フォルダの変更を監視
  void _watchFolder(String folderPath) {
    final directory = Directory(folderPath);
    directory.watch().listen((event) {
      _getPDFFilesFromFolder(folderPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _getPDFFilesFromFolder(_folderPath!),
            tooltip: 'リフレッシュ',
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _requestFolderAccess,
            tooltip: 'フォルダを選択',
          ),
        ],
      ),
      body: _folderPath == null || _isLoading
          ? _buildLoadingScreen()   // フォルダ選択待ちの画面
          : _pdfFiles.isEmpty
              ? _buildEmptyScreen() // PDFファイルが見つからない場合の画面
              : _buildPDFList(),    // PDFファイル一覧の画面
    );
  }

  // フォルダ選択待ちの画面を構築
  Widget _buildLoadingScreen() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // PDFファイルが見つからない場合の画面を構築
  Widget _buildEmptyScreen() {
    return const Center(
      child: Text('選択したフォルダにPDFファイルがありません'),
    );
  }

  // PDFファイル一覧の画面を構築
  Widget _buildPDFList() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 列数を指定
        childAspectRatio: 0.7, // カードの縦横比
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: _pdfFiles.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // PDF 詳細画面へ遷移
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PDFDetailScreen(filePath: _pdfFiles[index]),
              ),
            );
          },
          child: Card(
            elevation: 4.0,
            child: Column(
              children: [
                Expanded(
                  child: PDFThumbnail(
                    filePath: _pdfFiles[index],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _pdfFiles[index].split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
