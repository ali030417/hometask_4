import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:superheroes/blocs/main_bloc.dart';
import 'package:superheroes/pages/superhero_page.dart';
import 'package:superheroes/resources/superheroes_colors.dart';
import 'package:superheroes/resources/superheroes_images.dart';
import 'package:superheroes/widgets/action_button.dart';
import 'package:superheroes/widgets/info_with_button.dart';
import 'package:superheroes/widgets/superhero_card.dart';

class MainPage extends StatefulWidget {
  final http.Client? client;
  const MainPage({Key? key, this.client}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

// class MainBlocHolder extends InheritedWidget{
//   final MainBloc block;
//   const MainBlocHolder({super.key, required final Widget child, required this.block}):super(child: child);

//   @override
//   bool updateShouldNotify(MainBlocHolder oldWidget) => false;

//   static MainBlocHolder of(final BuildContext context){
//     final InheritedElement element = context.getElementForInheritedWidgetOfExactType<MainBlocHolder>()!;
//     return element.widget as MainBlocHolder;
//   }
// }

class _MainPageState extends State<MainPage> {
  late MainBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = MainBloc(client: widget.client);
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: const Scaffold(
        backgroundColor: SuperheroesColors.background,
        body: SafeArea(
          child: MainPageContant(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}

class MainPageContant extends StatefulWidget {
  const MainPageContant({super.key});

  @override
  State<MainPageContant> createState() => _MainPageContantState();
}

class _MainPageContantState extends State<MainPageContant> {
  late FocusNode searchFieldFocusNode;

  @override
  void initState() {
    super.initState();
    searchFieldFocusNode = FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MainPageStateWidget(searchFieldFocusNode: searchFieldFocusNode),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 16, top: 12),
          child: SearchWidget(searchFieldFocusNode: searchFieldFocusNode),
        ),
      ],
    );
  }

  @override
  void dispose() {
    searchFieldFocusNode.dispose();
    super.dispose();
  }
}

class SearchWidget extends StatefulWidget {
  final FocusNode searchFieldFocusNode;
  const SearchWidget({super.key, required this.searchFieldFocusNode});
  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController controller = TextEditingController();
  bool haveSearchText = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance?.addPostFrameCallback((timeStamp) {
      final MainBloc bloc = Provider.of<MainBloc>(context, listen: false);
      controller.addListener(() {
        bloc.updateText(controller.text);
        final haveText = controller.text.isNotEmpty;
        if (haveSearchText != haveText) {
          setState(() {
            haveSearchText = haveText;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: widget.searchFieldFocusNode,
      cursorColor: Colors.white,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.search,
      controller: controller,
      style: const TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        filled: true,
        fillColor: SuperheroesColors.indigo75,
        isDense: true,
        prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 24),
        suffix: GestureDetector(
          onTap: () => controller.clear(),
          child: const Icon(
            Icons.clear,
            color: Colors.white,
          ),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: haveSearchText
              ? const BorderSide(color: Colors.white)
              : const BorderSide(color: Colors.white24),
        ),
      ),
    );
  }
}

class MainPageStateWidget extends StatelessWidget {
  final FocusNode searchFieldFocusNode;
  const MainPageStateWidget({
    Key? key,
    required this.searchFieldFocusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MainBloc bloc = Provider.of<MainBloc>(context, listen: false);
    return StreamBuilder<MainPageState>(
      stream: bloc.observeMainPageState(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox();
        }
        final MainPageState state = snapshot.data!;
        switch (state) {
          case MainPageState.loading:
            return const LoadingIdinticator();
          case MainPageState.favorites:
            return Stack(
              children: [
                SuperheroList(
                  title: 'Your favorites',
                  stream: bloc.observeFavoriteSuperheroes(),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ActionButton(
                    text: 'Remove',
                    onTap: bloc.removeFavorite,
                  ),
                )
              ],
            );
          case MainPageState.noFavorites:
            return Stack(
              children: [
                NoFavoritesWidget(
                  searchFieldFocusNode: searchFieldFocusNode,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child:
                      ActionButton(text: 'Remove', onTap: bloc.removeFavorite),
                )
              ],
            );
          case MainPageState.minSymbols:
            return const MinSimbolsWidget();
          case MainPageState.nothingFound:
            return NothingFound(searchFieldFocusNode: searchFieldFocusNode);
          case MainPageState.loadingError:
            return const LoadingError();
          case MainPageState.searchResults:
            return SuperheroList(
              title: 'Search results',
              stream: bloc.observeSearchedSuperheroes(),
            );
          default:
            return Center(
                child: Text(
              state.toString(),
              style: const TextStyle(color: Colors.white),
            ));
        }
      },
    );
  }
}

class SuperheroList extends StatelessWidget {
  final String title;
  final Stream<List<SuperheroInfo>> stream;

  const SuperheroList({
    Key? key,
    required this.title,
    required this.stream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SuperheroInfo>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox();
        }
        final List<SuperheroInfo> superheroes = snapshot.data!;
        return ListView.separated(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: superheroes.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 90, bottom: 12),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }
            final SuperheroInfo item = superheroes[index - 1];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SuperheroCard(
                superheroInfo: item,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SuperheroPage(name: item.name),
                    ),
                  );
                },
              ),
            );
          },
          separatorBuilder: (BuildContext context, int index) {
            return const SizedBox(height: 8);
          },
        );
      },
    );
  }
}

class MinSimbolsWidget extends StatelessWidget {
  const MinSimbolsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 110),
        child: Text(
          'Enter at least 3 symbols',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
        ),
      ),
    );
  }
}

class NoFavoritesWidget extends StatelessWidget {
  final FocusNode searchFieldFocusNode;
  const NoFavoritesWidget({
    super.key,
    required this.searchFieldFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InfoWithButton(
        title: 'No favorites yet',
        subtitle: 'SEARCH AND ADD',
        buttonText: 'Search',
        assetImage: SuperheroesImages.ironman,
        imageHeight: 119,
        imageWidth: 108,
        imageTopPadding: 9,
        onTap: () => searchFieldFocusNode.requestFocus(),
      ),
    );
  }
}

class NothingFound extends StatelessWidget {
  final FocusNode searchFieldFocusNode;
  const NothingFound({
    super.key,
    required this.searchFieldFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InfoWithButton(
        title: 'Nothing found',
        subtitle: 'Search for something else',
        buttonText: 'Search',
        assetImage: SuperheroesImages.halk,
        imageHeight: 112,
        imageWidth: 84,
        imageTopPadding: 16,
        onTap: () => searchFieldFocusNode.requestFocus(),
      ),
    );
  }
}

class LoadingError extends StatelessWidget {
  const LoadingError({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InfoWithButton(
        title: 'Error happened',
        subtitle: 'Please, try again',
        buttonText: 'Retry',
        assetImage: SuperheroesImages.superman,
        imageHeight: 106,
        imageWidth: 126,
        imageTopPadding: 22,
        onTap: () {},
      ),
    );
  }
}

class LoadingIdinticator extends StatelessWidget {
  const LoadingIdinticator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 110),
        child: CircularProgressIndicator(
          color: SuperheroesColors.blue,
          strokeWidth: 4,
        ),
      ),
    );
  }
}
