import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'downloads_cubit.dart';
import 'downloads_state.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => DownloadsCubit(),
      child: Builder(builder: (context) => _buildPage(context)),
    );
  }

  Widget _buildPage(BuildContext context) {
    final cubit = BlocProvider.of<DownloadsCubit>(context);

    return Container();
  }
}


