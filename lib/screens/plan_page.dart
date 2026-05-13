import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'monthly_page.dart';
import 'scan_page.dart';
import 'dart:ui';
import '../models/meal.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  bool isWeeklyView = true;
  bool isEditing = false;

  DateTime _currentWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );

  final Map<String, dynamic> _mealPlan = <String, dynamic>{};

  final List<Map<String, dynamic>> _allRecipes = [
    {"id":1,"name":"Classic Margherita Pizza","ingredients":["Pizza dough","Tomato sauce","Fresh mozzarella cheese","Fresh basil leaves","Olive oil","Salt and pepper to taste"],"instructions":["Preheat the oven to 475°F (245°C).","Roll out the pizza dough and spread tomato sauce evenly.","Top with slices of fresh mozzarella and fresh basil leaves.","Drizzle with olive oil and season with salt and pepper.","Bake in the preheated oven for 12-15 minutes or until the crust is golden brown.","Slice and serve hot."],"prepTimeMinutes":20,"cookTimeMinutes":15,"servings":4,"difficulty":"Easy","cuisine":"Italian","caloriesPerServing":300,"tags":["Pizza","Italian"],"userId":166,"image":"https://cdn.dummyjson.com/recipe-images/1.webp","rating":4.6,"reviewCount":98,"mealType":["Dinner"]},
    {"id":2,"name":"Vegetarian Stir-Fry","ingredients":["Tofu, cubed","Broccoli florets","Carrots, sliced","Bell peppers, sliced","Soy sauce","Ginger, minced","Garlic, minced","Sesame oil","Cooked rice for serving"],"instructions":["In a wok, heat sesame oil over medium-high heat.","Add minced ginger and garlic, sauté until fragrant.","Add cubed tofu and stir-fry until golden brown.","Add broccoli, carrots, and bell peppers. Cook until vegetables are tender-crisp.","Pour soy sauce over the stir-fry and toss to combine.","Serve over cooked rice."],"prepTimeMinutes":15,"cookTimeMinutes":20,"servings":3,"difficulty":"Medium","cuisine":"Asian","caloriesPerServing":250,"tags":["Vegetarian","Stir-fry","Asian"],"userId":143,"image":"https://cdn.dummyjson.com/recipe-images/2.webp","rating":4.7,"reviewCount":26,"mealType":["Lunch"]},
    {"id":3,"name":"Chocolate Chip Cookies","ingredients":["All-purpose flour","Butter, softened","Brown sugar","White sugar","Eggs","Vanilla extract","Baking soda","Salt","Chocolate chips"],"instructions":["Preheat the oven to 350°F (175°C).","In a bowl, cream together softened butter, brown sugar, and white sugar.","Beat in eggs one at a time, then stir in vanilla extract.","Combine flour, baking soda, and salt. Gradually add to the wet ingredients.","Fold in chocolate chips.","Drop rounded tablespoons of dough onto ungreased baking sheets.","Bake for 10-12 minutes or until edges are golden brown.","Allow cookies to cool on the baking sheet for a few minutes before transferring to a wire rack."],"prepTimeMinutes":15,"cookTimeMinutes":10,"servings":24,"difficulty":"Easy","cuisine":"American","caloriesPerServing":150,"tags":["Cookies","Dessert","Baking"],"userId":34,"image":"https://cdn.dummyjson.com/recipe-images/3.webp","rating":4.9,"reviewCount":13,"mealType":["Snack","Dessert"]},
    {"id":4,"name":"Chicken Alfredo Pasta","ingredients":["Fettuccine pasta","Chicken breast, sliced","Heavy cream","Parmesan cheese, grated","Garlic, minced","Butter","Salt and pepper to taste","Fresh parsley for garnish"],"instructions":["Cook fettuccine pasta according to package instructions.","In a pan, sauté sliced chicken in butter until fully cooked.","Add minced garlic and cook until fragrant.","Pour in heavy cream and grated Parmesan cheese. Stir until the cheese is melted.","Season with salt and pepper to taste.","Combine the Alfredo sauce with cooked pasta.","Garnish with fresh parsley before serving."],"prepTimeMinutes":15,"cookTimeMinutes":20,"servings":4,"difficulty":"Medium","cuisine":"Italian","caloriesPerServing":500,"tags":["Pasta","Chicken"],"userId":136,"image":"https://cdn.dummyjson.com/recipe-images/4.webp","rating":4.9,"reviewCount":82,"mealType":["Lunch","Dinner"]},
    {"id":5,"name":"Mango Salsa Chicken","ingredients":["Chicken thighs","Mango, diced","Red onion, finely chopped","Cilantro, chopped","Lime juice","Jalapeño, minced","Salt and pepper to taste","Cooked rice for serving"],"instructions":["Season chicken thighs with salt and pepper.","Grill or bake chicken until fully cooked.","In a bowl, combine diced mango, chopped red onion, cilantro, minced jalapeño, and lime juice.","Dice the cooked chicken and mix it with the mango salsa.","Serve over cooked rice."],"prepTimeMinutes":15,"cookTimeMinutes":25,"servings":3,"difficulty":"Easy","cuisine":"Mexican","caloriesPerServing":380,"tags":["Chicken","Salsa"],"userId":26,"image":"https://cdn.dummyjson.com/recipe-images/5.webp","rating":4.9,"reviewCount":63,"mealType":["Dinner"]},
    {"id":6,"name":"Quinoa Salad with Avocado","ingredients":["Quinoa, cooked","Avocado, diced","Cherry tomatoes, halved","Cucumber, diced","Red bell pepper, diced","Feta cheese, crumbled","Lemon vinaigrette dressing","Salt and pepper to taste"],"instructions":["In a large bowl, combine cooked quinoa, diced avocado, halved cherry tomatoes, diced cucumber, diced red bell pepper, and crumbled feta cheese.","Drizzle with lemon vinaigrette dressing and toss to combine.","Season with salt and pepper to taste.","Chill in the refrigerator before serving."],"prepTimeMinutes":20,"cookTimeMinutes":15,"servings":4,"difficulty":"Easy","cuisine":"Mediterranean","caloriesPerServing":280,"tags":["Salad","Quinoa"],"userId":197,"image":"https://cdn.dummyjson.com/recipe-images/6.webp","rating":4.4,"reviewCount":59,"mealType":["Lunch","Side Dish"]},
    {"id":7,"name":"Tomato Basil Bruschetta","ingredients":["Baguette, sliced","Tomatoes, diced","Fresh basil, chopped","Garlic cloves, minced","Balsamic glaze","Olive oil","Salt and pepper to taste"],"instructions":["Preheat the oven to 375°F (190°C).","Place baguette slices on a baking sheet and toast in the oven until golden brown.","In a bowl, combine diced tomatoes, chopped fresh basil, minced garlic, and a drizzle of olive oil.","Season with salt and pepper to taste.","Top each toasted baguette slice with the tomato-basil mixture.","Drizzle with balsamic glaze before serving."],"prepTimeMinutes":15,"cookTimeMinutes":10,"servings":6,"difficulty":"Easy","cuisine":"Italian","caloriesPerServing":120,"tags":["Bruschetta","Italian"],"userId":137,"image":"https://cdn.dummyjson.com/recipe-images/7.webp","rating":4.7,"reviewCount":95,"mealType":["Appetizer"]},
    {"id":8,"name":"Beef and Broccoli Stir-Fry","ingredients":["Beef sirloin, thinly sliced","Broccoli florets","Soy sauce","Oyster sauce","Sesame oil","Garlic, minced","Ginger, minced","Cornstarch","Cooked white rice for serving"],"instructions":["In a bowl, mix soy sauce, oyster sauce, sesame oil, and cornstarch to create the sauce.","In a wok, stir-fry thinly sliced beef until browned. Remove from the wok.","Stir-fry broccoli florets, minced garlic, and minced ginger in the same wok.","Add the cooked beef back to the wok and pour the sauce over the mixture.","Stir until everything is coated and heated through.","Serve over cooked white rice."],"prepTimeMinutes":20,"cookTimeMinutes":15,"servings":4,"difficulty":"Medium","cuisine":"Asian","caloriesPerServing":380,"tags":["Beef","Stir-fry","Asian"],"userId":18,"image":"https://cdn.dummyjson.com/recipe-images/8.webp","rating":4.7,"reviewCount":58,"mealType":["Dinner"]},
    {"id":9,"name":"Caprese Salad","ingredients":["Tomatoes, sliced","Fresh mozzarella cheese, sliced","Fresh basil leaves","Balsamic glaze","Extra virgin olive oil","Salt and pepper to taste"],"instructions":["Arrange alternating slices of tomatoes and fresh mozzarella on a serving platter.","Tuck fresh basil leaves between the slices.","Drizzle with balsamic glaze and extra virgin olive oil.","Season with salt and pepper to taste.","Serve immediately as a refreshing salad."],"prepTimeMinutes":10,"cookTimeMinutes":0,"servings":2,"difficulty":"Easy","cuisine":"Italian","caloriesPerServing":200,"tags":["Salad","Caprese"],"userId":128,"image":"https://cdn.dummyjson.com/recipe-images/9.webp","rating":4.6,"reviewCount":82,"mealType":["Lunch"]},
    {"id":10,"name":"Shrimp Scampi Pasta","ingredients":["Linguine pasta","Shrimp, peeled and deveined","Garlic, minced","White wine","Lemon juice","Red pepper flakes","Fresh parsley, chopped","Salt and pepper to taste"],"instructions":["Cook linguine pasta according to package instructions.","In a skillet, sauté minced garlic in olive oil until fragrant.","Add shrimp and cook until pink and opaque.","Pour in white wine and lemon juice. Simmer until the sauce slightly thickens.","Season with red pepper flakes, salt, and pepper.","Toss cooked linguine in the shrimp scampi sauce.","Garnish with chopped fresh parsley before serving."],"prepTimeMinutes":15,"cookTimeMinutes":20,"servings":3,"difficulty":"Medium","cuisine":"Italian","caloriesPerServing":400,"tags":["Pasta","Shrimp"],"userId":114,"image":"https://cdn.dummyjson.com/recipe-images/10.webp","rating":4.3,"reviewCount":5,"mealType":["Dinner"]},
    {"id":11,"name":"Chicken Biryani","ingredients":["Basmati rice","Chicken, cut into pieces","Onions, thinly sliced","Tomatoes, chopped","Yogurt","Ginger-garlic paste","Biryani masala","Green chilies, sliced","Fresh coriander leaves","Mint leaves","Ghee","Salt to taste"],"instructions":["Marinate chicken with yogurt, ginger-garlic paste, biryani masala, and salt.","In a pot, sauté sliced onions until golden brown. Remove half for later use.","Layer marinated chicken, chopped tomatoes, half of the fried onions, and rice in the pot.","Top with ghee, green chilies, fresh coriander leaves, mint leaves, and the remaining fried onions.","Cover and cook on low heat until the rice is fully cooked and aromatic.","Serve hot, garnished with additional coriander and mint leaves."],"prepTimeMinutes":30,"cookTimeMinutes":45,"servings":6,"difficulty":"Medium","cuisine":"Pakistani","caloriesPerServing":550,"tags":["Biryani","Chicken","Main course","Indian","Pakistani","Asian"],"userId":133,"image":"https://cdn.dummyjson.com/recipe-images/11.webp","rating":5,"reviewCount":32,"mealType":["Lunch","Dinner"]},
    {"id":12,"name":"Chicken Karahi","ingredients":["Chicken, cut into pieces","Tomatoes, chopped","Green chilies, sliced","Ginger, julienned","Garlic, minced","Coriander powder","Cumin powder","Red chili powder","Garam masala","Cooking oil","Fresh coriander leaves","Salt to taste"],"instructions":["In a wok (karahi), heat cooking oil and sauté minced garlic until golden brown.","Add chicken pieces and cook until browned on all sides.","Add chopped tomatoes, green chilies, ginger, and spices. Cook until tomatoes are soft.","Cover and simmer until the chicken is tender and the oil separates from the masala.","Garnish with fresh coriander leaves and serve hot with naan or rice."],"prepTimeMinutes":20,"cookTimeMinutes":30,"servings":4,"difficulty":"Easy","cuisine":"Pakistani","caloriesPerServing":420,"tags":["Chicken","Karahi","Main course","Indian","Pakistani","Asian"],"userId":49,"image":"https://cdn.dummyjson.com/recipe-images/12.webp","rating":4.8,"reviewCount":68,"mealType":["Lunch","Dinner"]},
    {"id":13,"name":"Aloo Keema","ingredients":["Ground beef","Potatoes, peeled and diced","Onions, finely chopped","Tomatoes, chopped","Ginger-garlic paste","Cumin powder","Coriander powder","Turmeric powder","Red chili powder","Cooking oil","Fresh coriander leaves","Salt to taste"],"instructions":["In a pan, heat cooking oil and sauté chopped onions until golden brown.","Add ginger-garlic paste and sauté until fragrant.","Add ground beef and cook until browned. Drain excess oil if needed.","Add diced potatoes, chopped tomatoes, and spices. Mix well.","Cover and simmer until the potatoes are tender and the masala is well-cooked.","Garnish with fresh coriander leaves and serve hot with naan or rice."],"prepTimeMinutes":25,"cookTimeMinutes":35,"servings":5,"difficulty":"Medium","cuisine":"Pakistani","caloriesPerServing":380,"tags":["Keema","Potatoes","Main course","Pakistani","Asian"],"userId":152,"image":"https://cdn.dummyjson.com/recipe-images/13.webp","rating":4.6,"reviewCount":53,"mealType":["Lunch","Dinner"]},
    {"id":14,"name":"Chapli Kebabs","ingredients":["Ground beef","Onions, finely chopped","Tomatoes, finely chopped","Green chilies, chopped","Coriander leaves, chopped","Pomegranate seeds","Ginger-garlic paste","Cumin powder","Coriander powder","Red chili powder","Egg","Cooking oil","Salt to taste"],"instructions":["In a large bowl, mix ground beef, chopped onions, tomatoes, green chilies, coriander leaves, and pomegranate seeds.","Add ginger-garlic paste, cumin powder, coriander powder, red chili powder, and salt. Mix well.","Add an egg to bind the mixture and form into round flat kebabs.","Heat cooking oil in a pan and shallow fry the kebabs until browned on both sides.","Serve hot with naan or mint chutney."],"prepTimeMinutes":30,"cookTimeMinutes":20,"servings":4,"difficulty":"Medium","cuisine":"Pakistani","caloriesPerServing":320,"tags":["Kebabs","Beef","Indian","Pakistani","Asian"],"userId":152,"image":"https://cdn.dummyjson.com/recipe-images/14.webp","rating":4.7,"reviewCount":98,"mealType":["Lunch","Dinner","Snacks"]},
    {"id":15,"name":"Saag (Spinach) with Makki di Roti","ingredients":["Mustard greens, washed and chopped","Spinach, washed and chopped","Cornmeal (makki ka atta)","Onions, finely chopped","Green chilies, chopped","Ginger, grated","Ghee","Salt to taste"],"instructions":["Boil mustard greens and spinach until tender. Drain and blend into a coarse paste.","In a pan, sauté chopped onions, green chilies, and grated ginger in ghee until golden brown.","Add the greens paste and cook until it thickens.","Meanwhile, knead cornmeal with water to make a dough. Roll into rotis (flatbreads).","Cook the rotis on a griddle until golden brown.","Serve hot saag with makki di roti and a dollop of ghee."],"prepTimeMinutes":40,"cookTimeMinutes":30,"servings":3,"difficulty":"Medium","cuisine":"Pakistani","caloriesPerServing":280,"tags":["Saag","Roti","Main course","Indian","Pakistani","Asian"],"userId":43,"image":"https://cdn.dummyjson.com/recipe-images/15.webp","rating":4.3,"reviewCount":86,"mealType":["Breakfast","Lunch","Dinner"]},
    {"id":16,"name":"Japanese Ramen Soup","ingredients":["Ramen noodles","Chicken broth","Soy sauce","Mirin","Sesame oil","Shiitake mushrooms, sliced","Bok choy, chopped","Green onions, sliced","Soft-boiled eggs","Grilled chicken slices","Norwegian seaweed (nori)"],"instructions":["Cook ramen noodles according to package instructions and set aside.","In a pot, combine chicken broth, soy sauce, mirin, and sesame oil. Bring to a simmer.","Add sliced shiitake mushrooms and chopped bok choy. Cook until vegetables are tender.","Divide the cooked noodles into serving bowls and ladle the hot broth over them.","Top with green onions, soft-boiled eggs, grilled chicken slices, and nori.","Serve hot and enjoy the authentic Japanese ramen!"],"prepTimeMinutes":20,"cookTimeMinutes":25,"servings":2,"difficulty":"Medium","cuisine":"Japanese","caloriesPerServing":480,"tags":["Ramen","Japanese","Soup","Asian"],"userId":85,"image":"https://cdn.dummyjson.com/recipe-images/16.webp","rating":4.9,"reviewCount":38,"mealType":["Dinner"]},
    {"id":17,"name":"Moroccan Chickpea Tagine","ingredients":["Chickpeas, cooked","Tomatoes, chopped","Carrots, diced","Onions, finely chopped","Garlic, minced","Cumin","Coriander","Cinnamon","Paprika","Vegetable broth","Olives","Fresh cilantro, chopped"],"instructions":["In a tagine or large pot, sauté chopped onions and minced garlic until softened.","Add diced carrots, chopped tomatoes, and cooked chickpeas.","Season with cumin, coriander, cinnamon, and paprika. Stir to coat.","Pour in vegetable broth and bring to a simmer. Cook until carrots are tender.","Stir in olives and garnish with fresh cilantro before serving.","Serve this flavorful Moroccan dish with couscous or crusty bread."],"prepTimeMinutes":15,"cookTimeMinutes":30,"servings":4,"difficulty":"Easy","cuisine":"Moroccan","caloriesPerServing":320,"tags":["Tagine","Chickpea","Moroccan"],"userId":207,"image":"https://cdn.dummyjson.com/recipe-images/17.webp","rating":4.5,"reviewCount":50,"mealType":["Dinner"]},
    {"id":18,"name":"Korean Bibimbap","ingredients":["Cooked white rice","Beef bulgogi (marinated and grilled beef slices)","Carrots, julienned and sautéed","Spinach, blanched and seasoned","Zucchini, sliced and grilled","Bean sprouts, blanched","Fried egg","Gochujang (Korean red pepper paste)","Sesame oil","Toasted sesame seeds"],"instructions":["Arrange cooked white rice in a bowl.","Top with beef bulgogi, sautéed carrots, seasoned spinach, grilled zucchini, and blanched bean sprouts.","Place a fried egg on top and drizzle with gochujang and sesame oil.","Sprinkle with toasted sesame seeds before serving.","Mix everything together before enjoying this delicious Korean bibimbap!","Feel free to customize with additional vegetables or protein."],"prepTimeMinutes":30,"cookTimeMinutes":20,"servings":2,"difficulty":"Medium","cuisine":"Korean","caloriesPerServing":550,"tags":["Bibimbap","Korean","Rice"],"userId":121,"image":"https://cdn.dummyjson.com/recipe-images/18.webp","rating":4.9,"reviewCount":56,"mealType":["Dinner"]},
    {"id":19,"name":"Greek Moussaka","ingredients":["Eggplants, sliced","Ground lamb or beef","Onions, finely chopped","Garlic, minced","Tomatoes, crushed","Red wine","Cinnamon","Allspice","Nutmeg","Olive oil","Milk","Flour","Parmesan cheese","Egg yolks"],"instructions":["Preheat oven to 375°F (190°C).","Sauté sliced eggplants in olive oil until browned. Set aside.","In the same pan, cook chopped onions and minced garlic until softened.","Add ground lamb or beef and brown. Stir in crushed tomatoes, red wine, and spices.","In a separate saucepan, make béchamel sauce: melt butter, whisk in flour, add milk, and cook until thickened.","Remove from heat and stir in Parmesan cheese and egg yolks.","In a baking dish, layer eggplants and meat mixture. Top with béchamel sauce.","Bake for 40-45 minutes until golden brown. Let it cool before slicing.","Serve slices of moussaka warm and enjoy this Greek classic!"],"prepTimeMinutes":45,"cookTimeMinutes":45,"servings":6,"difficulty":"Medium","cuisine":"Greek","caloriesPerServing":420,"tags":["Moussaka","Greek"],"userId":173,"image":"https://cdn.dummyjson.com/recipe-images/19.webp","rating":4.3,"reviewCount":26,"mealType":["Dinner"]},
    {"id":20,"name":"Butter Chicken (Murgh Makhani)","ingredients":["Chicken thighs, boneless and skinless","Yogurt","Ginger-garlic paste","Garam masala","Kashmiri red chili powder","Tomato puree","Butter","Heavy cream","Kasuri methi (dried fenugreek leaves)","Sugar","Salt to taste"],"instructions":["Marinate chicken thighs in a mixture of yogurt, ginger-garlic paste, garam masala, and Kashmiri red chili powder.","In a pan, melt butter and sauté the marinated chicken until browned.","Add tomato puree and cook until the oil separates. Stir in heavy cream.","Sprinkle kasuri methi, sugar, and salt. Simmer until the chicken is fully cooked.","Serve this creamy butter chicken over rice or with naan for an authentic Pakistani/Indian experience."],"prepTimeMinutes":30,"cookTimeMinutes":25,"servings":4,"difficulty":"Medium","cuisine":"Pakistani","caloriesPerServing":480,"tags":["Butter chicken","Curry","Indian","Pakistani","Asian"],"userId":138,"image":"https://cdn.dummyjson.com/recipe-images/20.webp","rating":4.5,"reviewCount":44,"mealType":["Dinner"]},
    {"id":21,"name":"Thai Green Curry","ingredients":["Chicken thighs, boneless and skinless","Green curry paste","Coconut milk","Fish sauce","Sugar","Eggplant, sliced","Bell peppers, sliced","Basil leaves","Jasmine rice for serving"],"instructions":["In a pot, simmer green curry paste in coconut milk.","Add chicken, fish sauce, and sugar. Cook until chicken is tender.","Stir in sliced eggplant and bell peppers. Simmer until vegetables are cooked.","Garnish with fresh basil leaves.","Serve hot over jasmine rice and enjoy this Thai classic!"],"prepTimeMinutes":20,"cookTimeMinutes":30,"servings":4,"difficulty":"Medium","cuisine":"Thai","caloriesPerServing":480,"tags":["Curry","Thai"],"userId":153,"image":"https://cdn.dummyjson.com/recipe-images/21.webp","rating":4.2,"reviewCount":18,"mealType":["Dinner"]},
    {"id":22,"name":"Mango Lassi","ingredients":["Ripe mango, peeled and diced","Yogurt","Milk","Honey","Cardamom powder","Ice cubes"],"instructions":["In a blender, combine diced mango, yogurt, milk, honey, and cardamom powder.","Blend until smooth and creamy.","Add ice cubes and blend again until the lassi is chilled.","Pour into glasses and garnish with a sprinkle of cardamom.","Enjoy this refreshing Mango Lassi!"],"prepTimeMinutes":10,"cookTimeMinutes":0,"servings":2,"difficulty":"Easy","cuisine":"Indian","caloriesPerServing":180,"tags":["Lassi","Mango","Indian","Pakistani","Asian"],"userId":76,"image":"https://cdn.dummyjson.com/recipe-images/22.webp","rating":4.7,"reviewCount":15,"mealType":["Beverage"]},
    {"id":23,"name":"Italian Tiramisu","ingredients":["Espresso, brewed and cooled","Ladyfinger cookies","Mascarpone cheese","Heavy cream","Sugar","Cocoa powder"],"instructions":["In a bowl, whip heavy cream until stiff peaks form.","In another bowl, mix mascarpone cheese and sugar until smooth.","Gently fold the whipped cream into the mascarpone mixture.","Dip ladyfinger cookies into brewed espresso and layer them in a serving dish.","Spread a layer of the mascarpone mixture over the cookies.","Repeat layers and finish with a dusting of cocoa powder.","Chill in the refrigerator for a few hours before serving.","Indulge in the decadence of this classic Italian Tiramisu!"],"prepTimeMinutes":30,"cookTimeMinutes":0,"servings":6,"difficulty":"Medium","cuisine":"Italian","caloriesPerServing":350,"tags":["Tiramisu","Italian"],"userId":130,"image":"https://cdn.dummyjson.com/recipe-images/23.webp","rating":4.6,"reviewCount":0,"mealType":["Dessert"]},
    {"id":24,"name":"Turkish Kebabs","ingredients":["Ground lamb or beef","Onions, grated","Garlic, minced","Parsley, finely chopped","Cumin","Coriander","Red pepper flakes","Salt and pepper to taste","Flatbread for serving","Tahini sauce"],"instructions":["In a bowl, mix ground meat, grated onions, minced garlic, chopped parsley, and spices.","Form the mixture into kebab shapes and grill until fully cooked.","Serve the kebabs on flatbread with a drizzle of tahini sauce.","Enjoy these flavorful Turkish Kebabs with your favorite sides."],"prepTimeMinutes":25,"cookTimeMinutes":15,"servings":4,"difficulty":"Easy","cuisine":"Turkish","caloriesPerServing":280,"tags":["Kebabs","Turkish","Grilling"],"userId":26,"image":"https://cdn.dummyjson.com/recipe-images/24.webp","rating":4.6,"reviewCount":78,"mealType":["Dinner"]},
    {"id":25,"name":"Blueberry Banana Smoothie","ingredients":["Blueberries, fresh or frozen","Banana, peeled and sliced","Greek yogurt","Almond milk","Honey","Chia seeds (optional)"],"instructions":["In a blender, combine blueberries, banana, Greek yogurt, almond milk, and honey.","Blend until smooth and creamy.","Add chia seeds for extra nutrition and blend briefly.","Pour into a glass and enjoy this nutritious Blueberry Banana Smoothie!"],"prepTimeMinutes":10,"cookTimeMinutes":0,"servings":1,"difficulty":"Easy","cuisine":"Smoothie","caloriesPerServing":220,"tags":["Smoothie","Blueberry","Banana"],"userId":16,"image":"https://cdn.dummyjson.com/recipe-images/25.webp","rating":4.8,"reviewCount":30,"mealType":["Breakfast","Beverage"]},
    {"id":26,"name":"Mexican Street Corn (Elote)","ingredients":["Corn on the cob","Mayonnaise","Cotija cheese, crumbled","Chili powder","Lime wedges"],"instructions":["Grill or roast corn on the cob until kernels are charred.","Brush each cob with mayonnaise, then sprinkle with crumbled Cotija cheese and chili powder.","Serve with lime wedges for squeezing over the top.","Enjoy this delicious and flavorful Mexican Street Corn!"],"prepTimeMinutes":15,"cookTimeMinutes":15,"servings":4,"difficulty":"Easy","cuisine":"Mexican","caloriesPerServing":180,"tags":["Elote","Mexican","Street food"],"userId":93,"image":"https://cdn.dummyjson.com/recipe-images/26.webp","rating":4.6,"reviewCount":2,"mealType":["Snack","Side Dish"]},
    {"id":27,"name":"Russian Borscht","ingredients":["Beets, peeled and shredded","Cabbage, shredded","Potatoes, diced","Onions, finely chopped","Carrots, grated","Tomato paste","Beef or vegetable broth","Garlic, minced","Bay leaves","Sour cream for serving"],"instructions":["In a pot, sauté chopped onions and garlic until softened.","Add shredded beets, cabbage, diced potatoes, grated carrots, and tomato paste.","Pour in broth and add bay leaves. Simmer until vegetables are tender.","Serve hot with a dollop of sour cream on top.","Enjoy the hearty and comforting flavors of Russian Borscht!"],"prepTimeMinutes":30,"cookTimeMinutes":40,"servings":6,"difficulty":"Medium","cuisine":"Russian","caloriesPerServing":220,"tags":["Borscht","Russian","Soup"],"userId":1,"image":"https://cdn.dummyjson.com/recipe-images/27.webp","rating":4.3,"reviewCount":39,"mealType":["Dinner"]},
    {"id":28,"name":"South Indian Masala Dosa","ingredients":["Dosa batter (fermented rice and urad dal batter)","Potatoes, boiled and mashed","Onions, finely chopped","Mustard seeds","Cumin seeds","Curry leaves","Turmeric powder","Green chilies, chopped","Ghee","Coconut chutney for serving"],"instructions":["In a pan, heat ghee and add many seeds, cumin seeds, and curry leaves.","Add chopped onions, green chilies, and turmeric powder. Sauté until onions are golden brown.","Mix in boiled and mashed potatoes. Cook until well combined and seasoned.","Spread dosa batter on a hot griddle to make thin pancakes.","Place a spoonful of the potato mixture in the center, fold, and serve hot.","Pair with coconut chutney for a delicious South Indian meal."],"prepTimeMinutes":40,"cookTimeMinutes":20,"servings":4,"difficulty":"Medium","cuisine":"Indian","caloriesPerServing":320,"tags":["Dosa","Indian","Asian"],"userId":138,"image":"https://cdn.dummyjson.com/recipe-images/28.webp","rating":4.4,"reviewCount":96,"mealType":["Breakfast"]},
    {"id":29,"name":"Lebanese Falafel Wrap","ingredients":["Falafel balls","Whole wheat or regular wraps","Tomatoes, diced","Cucumbers, sliced","Red onions, thinly sliced","Lettuce, shredded","Tahini sauce","Fresh parsley, chopped"],"instructions":["Warm falafel balls according to package instructions.","Place a generic serving of falafel in the center of each wrap.","Top with diced tomatoes, sliced cucumbers, red onions, shredded lettuce, and fresh parsley.","Drizzle with tahini sauce and wrap tightly.","Enjoy this Lebanese Falafel Wrap filled with fresh and flavorful ingredients!"],"prepTimeMinutes":15,"cookTimeMinutes":10,"servings":2,"difficulty":"Easy","cuisine":"Lebanese","caloriesPerServing":400,"tags":["Falafel","Lebanese","Wrap"],"userId":110,"image":"https://cdn.dummyjson.com/recipe-images/29.webp","rating":4.7,"reviewCount":84,"mealType":["Lunch"]},
    {"id":30,"name":"Brazilian Caipirinha","ingredients":["Cachaça (Brazilian sugarcane spirit)","Lime, cut into wedges","Granulated sugar","Ice cubes"],"instructions":["In a glass, muddle lime wedges with granulated sugar to release the juice.","Fill the glass with ice cubes.","Pour cachaça over the ice and stir well.","Sip and enjoy the refreshing taste of the Brazilian Caipirinha!","Adjust sugar and lime to suit your taste preferences."],"prepTimeMinutes":5,"cookTimeMinutes":0,"servings":1,"difficulty":"Easy","cuisine":"Brazilian","caloriesPerServing":150,"tags":["Caipirinha","Brazilian","Cocktail"],"userId":134,"image":"https://cdn.dummyjson.com/recipe-images/30.webp","rating":4.4,"reviewCount":55,"mealType":["Beverage"]}
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    _currentWeekStart = DateTime(monday.year, monday.month, monday.day);
    _initializeMealPlan();
  }

  void _initializeMealPlan() {
    _mealPlan.clear();
    final List<String> mealTypes = ['Breakfast', 'Lunch', 'High Tea', 'Dinner', 'Snack'];
    final List<Map<String, dynamic>> shuffledRecipes = List<Map<String, dynamic>>.from(_allRecipes)..shuffle();

    int recipeIdx = 0;
    for (int i = 0; i < 7; i++) {
      final date = _currentWeekStart.add(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      
      final mealsCount = (recipeIdx % 3) + 1; 
      final dayMeals = <Meal>[];
      _mealPlan[dateKey] = dayMeals;
      
      for (int m = 0; m < mealsCount; m++) {
        if (recipeIdx < shuffledRecipes.length) {
          final recipe = shuffledRecipes[recipeIdx];
          dayMeals.add(
            Meal(
              title: recipe['name'],
              mealType: mealTypes[recipeIdx % mealTypes.length],
              servings: recipe['servings'] ?? 1,
              calories: recipe['caloriesPerServing'] ?? 0,
              originalData: recipe,
            ),
          );
          recipeIdx++;
        }
      }
    }
  }

  void _changeWeek(int days) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: days));
      _initializeMealPlan();
    });
  }

  void _deleteMeal(String dateKey, int index) {
    setState(() {
      final meals = _mealPlan[dateKey] as List<Meal>?;
      meals?.removeAt(index);
      if (meals?.isEmpty ?? false) {
        _mealPlan.remove(dateKey);
      }
    });
  }

  void _addMeal(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final List<String> mealTypes = ['Breakfast', 'Lunch', 'High Tea', 'Dinner', 'Snack'];
    final randomRecipe = (List<Map<String, dynamic>>.from(_allRecipes)..shuffle()).first;
    setState(() {
      if (!_mealPlan.containsKey(dateKey)) {
        _mealPlan[dateKey] = <Meal>[];
      }
      (_mealPlan[dateKey] as List<Meal>).add(
        Meal(
          title: randomRecipe['name'],
          mealType: mealTypes[(_mealPlan[dateKey] as List).length % mealTypes.length],
          servings: randomRecipe['servings'] ?? 1,
          calories: randomRecipe['caloriesPerServing'] ?? 0,
          originalData: randomRecipe,
        ),
      );
    });
  }

  Widget _buildMealPlanView(BuildContext context) {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final weekRange =
        '${DateFormat('MMM d').format(_currentWeekStart)} - ${DateFormat('MMM d').format(weekEnd)}';
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final currentWeekOfToday = todayStart.subtract(
      Duration(days: todayStart.weekday - 1),
    );
    final isThisWeek = _currentWeekStart.isAtSameMomentAs(currentWeekOfToday);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24.0),
          _buildViewToggle(),
          const SizedBox(height: 24.0),
          if (!isWeeklyView)
            MonthlyPage(
              mealPlan: _mealPlan,
              isEditing: isEditing,
              onDeleteMeal: (String dateKey) {
                setState(() {
                  _mealPlan.remove(dateKey);
                });
              },
            )
          else ...[
            _buildWeekNavigator(weekRange, isThisWeek),
            const SizedBox(height: 24.0),
            ...List.generate(7, (index) {
              final date = _currentWeekStart.add(Duration(days: index));
              final dateKey = DateFormat('yyyy-MM-dd').format(date);
              final meals = _mealPlan[dateKey] ?? <Meal>[];
              return DayContainer(
                date: date,
                meals: meals,
                isEditing: isEditing,
                onDeleteMeal: (idx) => _deleteMeal(dateKey, idx),
                onAddMeal: () => _addMeal(date),
                onMealTap: (meal) {
                  if (meal.originalData != null) {
                    context.pushNamed(
                      'recipe-view',
                      extra: Map<String, dynamic>.from(meal.originalData!),
                    );
                  }
                },
              );
            }),
          ],
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Meal Plan',
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003D33),
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              isWeeklyView ? 'Weekly view' : 'Monthly view',
              style: const TextStyle(fontSize: 14.0, color: Colors.grey),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => setState(() => isEditing = !isEditing),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: isEditing ? const Color(0xFF1BAB52) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Icon(
                  isEditing ? Icons.check : Icons.edit_outlined,
                  size: 18.0,
                  color: isEditing ? Colors.white : const Color(0xFF003D33),
                ),
                const SizedBox(width: 8.0),
                Text(
                  isEditing ? 'Done' : 'Edit',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isEditing ? Colors.white : const Color(0xFF003D33),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggle() {
    return Container(
      height: 44.0,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          _toggleItem('Weekly', Icons.calendar_today_outlined, isWeeklyView,
              () => setState(() => isWeeklyView = true)),
          _toggleItem('Monthly', Icons.calendar_view_month_outlined, !isWeeklyView,
              () => setState(() => isWeeklyView = false)),
        ],
      ),
    );
  }

  Widget _toggleItem(
      String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16.0, color: isSelected ? const Color(0xFF003D33) : Colors.grey),
              const SizedBox(width: 8.0),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? const Color(0xFF003D33) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekNavigator(String weekRange, bool isThisWeek) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navButton(Icons.chevron_left, 'Prev', () => _changeWeek(-7)),
          Column(
            children: [
              Text(
                weekRange,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003D33),
                ),
              ),
              if (isThisWeek)
                const Text(
                  'This Week',
                  style: TextStyle(fontSize: 12.0, color: Colors.grey),
                ),
            ],
          ),
          _navButton(Icons.chevron_right, 'Next', () => _changeWeek(7), isIconLeft: false),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, String label, VoidCallback onTap,
      {bool isIconLeft = true}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          if (isIconLeft) Icon(icon, color: const Color(0xFF1BAB52)),
          if (isIconLeft) const SizedBox(width: 4.0),
          Text(label,
              style: const TextStyle(color: Color(0xFF1BAB52), fontWeight: FontWeight.w600)),
          if (!isIconLeft) const SizedBox(width: 4.0),
          if (!isIconLeft) Icon(icon, color: const Color(0xFF1BAB52)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan',
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003D33),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  const Text(
                    'Manage meals and recipes',
                    style: TextStyle(fontSize: 14.0, color: Colors.grey),
                  ),
                  const SizedBox(height: 24.0),
                  _buildMainTabs(),
                ],
              ),
            ),
            Expanded(child: _buildMealPlanView(context)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScanPage.show(context),
        backgroundColor: const Color(0xFFFF7043),
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28.0),
      ),
    );
  }

  Widget _buildMainTabs() {
    return Container(
      height: 50.0,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4.0,
                    offset: const Offset(0.0, 2.0),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                'Meal Plan',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF003D33)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/my-recipes'),
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                child: const Text(
                  'My Recipes',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DayContainer extends StatelessWidget {
  final DateTime date;
  final List<Meal> meals;
  final bool isEditing;
  final VoidCallback onAddMeal;
  final Function(int) onDeleteMeal;
  final Function(Meal) onMealTap;

  const DayContainer({
    super.key,
    required this.date,
    required this.meals,
    required this.isEditing,
    required this.onAddMeal,
    required this.onDeleteMeal,
    required this.onMealTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('EEE').format(date);
    final dayNum = DateFormat('d').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 50.0,
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1BAB52),
                    ),
                  ),
                  Text(
                    dayNum,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1BAB52),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: meals.isEmpty
                ? _buildEmptyState()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...meals.asMap().entries.map((entry) {
                        return MealEntry(
                          meal: entry.value,
                          isLast: entry.key == meals.length - 1 && !isEditing,
                          onDelete: () => onDeleteMeal(entry.key),
                          onTap: () => onMealTap(entry.value),
                          isEditing: isEditing,
                        );
                      }),
                      if (isEditing)
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 5,
                                top: 0,
                                bottom: 0,
                                child: Container(width: 1.0, color: const Color(0xFFEEEEEE)),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                                child: GestureDetector(
                                  onTap: onAddMeal,
                                  child: Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: const Icon(Icons.add, color: Color(0xFF1BAB52), size: 20.0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return CustomPaint(
      painter: DottedBorderPainter(color: Colors.grey.withValues(alpha: 0.3)),
      child: InkWell(
        onTap: onAddMeal,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          height: 60.0,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add, color: Colors.grey, size: 20.0),
              SizedBox(width: 8.0),
              Text(
                'Plan a meal',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MealEntry extends StatelessWidget {
  final Meal meal;
  final bool isLast;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final bool isEditing;

  const MealEntry({
    super.key,
    required this.meal,
    required this.isLast,
    required this.onDelete,
    required this.onTap,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 9,
          top: 0,
          bottom: 0,
          child: isLast
              ? const SizedBox.shrink()
              : Container(
                  width: 1.0,
                  color: const Color(0xFFEEEEEE),
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Container(
                  width: 20.0,
                  alignment: Alignment.center,
                  child: Container(
                    width: 8.0,
                    height: 8.0,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDDDDDD),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8.0,
                          offset: const Offset(0.0, 4.0),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: _getMealTypeColor(meal.mealType).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  meal.mealType,
                                  style: TextStyle(
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.w800,
                                    color: _getMealTypeColor(meal.mealType),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                meal.title,
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003D33),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.people_outline, size: 14.0, color: Colors.grey),
                                  const SizedBox(width: 4.0),
                                  Text('${meal.servings}',
                                      style: const TextStyle(fontSize: 12.0, color: Colors.grey)),
                                  const SizedBox(width: 16.0),
                                  const Icon(Icons.local_fire_department_outlined,
                                      size: 14.0, color: Colors.grey),
                                  const SizedBox(width: 4.0),
                                  Text('${meal.calories}',
                                      style: const TextStyle(fontSize: 12.0, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isEditing)
                          GestureDetector(
                            onTap: onDelete,
                            child: Container(
                              padding: const EdgeInsets.all(6.0),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFEBEE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.delete_outline,
                                  color: Color(0xFFEF5350), size: 18.0),
                            ),
                          )
                        else
                          const Icon(Icons.chevron_right, color: Colors.grey, size: 20.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getMealTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.blue;
      case 'high tea':
        return Colors.teal;
      case 'dinner':
        return Colors.deepPurple;
      case 'snack':
        return Colors.brown;
      default:
        return const Color(0xFF1BAB52);
    }
  }
}

class DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DottedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromLTRBR(
      0,
      0,
      size.width,
      size.height,
      const Radius.circular(16.0),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    double distance = 0.0;
    for (final PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
      distance = 0.0;
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
