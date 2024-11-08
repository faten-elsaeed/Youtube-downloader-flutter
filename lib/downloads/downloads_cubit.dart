import 'package:bloc/bloc.dart';

import 'downloads_state.dart';

class DownloadsCubit extends Cubit<DownloadsState> {
  DownloadsCubit() : super(DownloadsState().init());
}
