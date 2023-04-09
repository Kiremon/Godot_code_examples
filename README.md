Примеры кода на GDScript (Godot), вырванные из проекта "Experiment", являющегося point-and-click адвенчурой по мотивам Звёздных Войн. Сам проект в целом не могу назвать удачным, многое там работает через костыли, потому тут привожу только те кусочки кода, за которые мне относительно не стыдно. Этот код частично я заимствую и для других своих проектов того же жанра.

GameChara.gd - базовый класс для управляемых игроком персонажей (в "Experiment" их двое с анимацией разной структуры). В нём относительно работоспособно сделан алгоритм поиска пути для обхода препятствий.

loc.gd - универсальный скрипт для всех локаций, обслуживающий функционал класса GameChara.

obstacle.gd - скрипт для нодов, хранящих преграды на локации.

scalezone.gd - скрипт для нодов, хранящих зоны масштабирования для персонажей на локации (где это необходимо для правильной работы перспективы).

---

Code examples in GDScript (Godot). Took them from my funfic-project "Experiment" - the point-and-click adventure based on Star Wars. Project in general is not very brilliant in terms of code, so I brought mainly those pieces I'm almost not ashamed of. Same algorithms I used in a few other my projects.

GameChara.gd - parent class for player's characters (there are two of then in "Experiment", with difference in animation structure). Path-finding algorithm is reasonably good in here.

loc.gd - generic script for all locations, needed by GameChara functionality.

obstacle.gd - script for Node, that contains obstacles of location.

scalezone.gd - script for Node, that contains scaling zone for character in location (so that a perspective could work fine).
