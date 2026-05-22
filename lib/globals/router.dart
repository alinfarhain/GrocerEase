import 'package:go_router/go_router.dart';
import '../screens/launch_screen.dart';
import '../onboarding_template/onboarding_screen.dart';
import '../screens/login_page.dart';
import '../screens/register_page.dart';
import '../screens/main_navigation_shell.dart';
import '../screens/recipe_view.dart';
import '../screens/recipe_edit.dart';
import '../screens/search_recipes.dart';
import '../screens/scan_page.dart';
import '../screens/navigate_page.dart';
import '../screens/my_recipes.dart';
import '../screens/scan_meal_screen.dart';    // ← ADD THIS
import '../screens/scan_results_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/launch',
  routes: [
    GoRoute(
      path: '/launch',
      name: 'launch',
      builder: (context, state) => const LaunchScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/navigate',
      name: 'navigate',
      builder: (context, state) => const NavigatePage(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/',
      name: 'main-page',
      builder: (context, state) => const MainNavigationShell(),
    ),
    GoRoute(
      path: '/recipe-view',
      name: 'recipe-view',
      builder: (context, state) {
        final dynamic extraValue = state.extra;
        final Map<String, dynamic> recipe = (extraValue is Map)
            ? Map<String, dynamic>.from(extraValue)
            : <String, dynamic>{};
        return RecipeView(recipe: recipe);
      },
    ),
    GoRoute(
      path: '/recipe-edit',
      name: 'recipe-edit',
      builder: (context, state) {
        final dynamic extraValue = state.extra;
        final Map<String, dynamic> recipe = (extraValue is Map)
            ? Map<String, dynamic>.from(extraValue)
            : <String, dynamic>{};
        return RecipeEdit(recipe: recipe);
      },
    ),
    GoRoute(
      path: '/search-recipes',
      name: 'search-recipes',
      builder: (context, state) => const SearchRecipes(),
    ),
    GoRoute(
      path: '/scan-page',
      name: 'scan-page',
      builder: (context, state) => const ScanPage(),
    ),

    GoRoute(
      path: '/scan-meal',
      name: 'scan-meal',
      builder: (context, state) => const ScanMealScreen(),
    ),
    GoRoute(
      path: '/scan-results',
      name: 'scan-results',
      builder: (context, state) {
        final dynamic extraValue = state.extra;
        final Map<String, dynamic> result = (extraValue is Map)
            ? Map<String, dynamic>.from(extraValue)
            : <String, dynamic>{};
        return ScanResultsScreen(result: result);
      },
    ),

    GoRoute(
      path: '/my-recipes',
      name: 'my-recipes',
      builder: (context, state) {
        final dynamic extraValue = state.extra;
        final bool initialEditMode =
            (extraValue is Map && extraValue.containsKey('editMode'))
                ? extraValue['editMode'] == true
                : false;
        return MyRecipes(initialEditMode: initialEditMode);
      },
    ),
  ],
);
