# The world stary_sacz: its sources in worlds/<WORLD>/, where the game's packs have them, and its
# description worlds/<WORLD>.json - written by the scenery importer (this repository in its sources
# folder), viewed in this Godot project, packed by world-packer (vendor/world-packer).

WORLD:=stary_sacz
# The checkouts linked into this project (make links) are given explicitly - there is no default:
# LIBMASZYNA (libmaszyna: its addons/libmaszyna, its vendor/gnd-sfx, its demo's built
# bin/libmaszyna), GND_BIOMES (godot-biomes: its addons/gnd_biomes), TERRAIN3D (the addons/terrain_3d
# of a double precision Terrain3D build) and WORLD_ASSETS (the world assets: what the worlds share,
# linked for this project's editor - the game mounts their packs), e.g.
#   make links LIBMASZYNA=<libmaszyna> GND_BIOMES=<godot-biomes> TERRAIN3D=<terrain_3d addon> \
#     WORLD_ASSETS=<world-assets>
# make packs needs none of them.
GODOT?=godot-double
# The make variable $(1) given, else make stops saying what it is ($(2)) and how to give it
require=$(if $($(1)),,$(error $(1) not given: $(2) - make $@ $(1)=<path>))

.PHONY: links editor packs world-name

# The world's name, for the CI's release
world-name:
	@echo $(WORLD)

# The addons of the other repositories and the world assets, linked as the world assets link theirs
links:
	$(call require,LIBMASZYNA,the libmaszyna checkout linked into this project)
	$(call require,GND_BIOMES,the godot-biomes checkout linked into this project)
	$(call require,TERRAIN3D,the addons/terrain_3d of a double precision Terrain3D build)
	$(call require,WORLD_ASSETS,the world assets checkout whose world_assets are linked)
	mkdir -p addons bin
	ln -sfn $(LIBMASZYNA)/addons/libmaszyna addons/libmaszyna
	ln -sfn $(LIBMASZYNA)/vendor/gnd-sfx/addons/gnd_sfx addons/gnd_sfx
	ln -sfn $(LIBMASZYNA)/demo/bin/libmaszyna bin/libmaszyna
	ln -sfn $(GND_BIOMES)/addons/gnd_biomes addons/gnd_biomes
	ln -sfn $(TERRAIN3D) addons/terrain_3d
	ln -sfn $(WORLD_ASSETS)/world_assets world_assets

editor: links
	$(GODOT) --path . --editor

# <WORLD>.zip - worlds/<WORLD>/ (world.pck, a pack a block) and worlds/<WORLD>.json, unzipped into
# the game directory - built headless in a project of its own, PACKS_PROJECT: no libmaszyna, only
# world-packer and worlds/ linked; the world's files are packed as they are, nothing imported.
# Hidden (a dot), this project's editor does not see it. The CI's release
# (.github/workflows/release.yml) is this.
PACKS_PROJECT:=.packs
PACKS_OUT?=$(PACKS_PROJECT)/out
packs:
	mkdir -p $(PACKS_PROJECT)/addons $(PACKS_OUT)
	printf '%s\n' 'config_version=5' '' '[application]' '' 'config/name="MaSzyna world packs"' \
		'config/features=PackedStringArray("4.7", "Double Precision")' '' > $(PACKS_PROJECT)/project.godot
	ln -sfn ../worlds $(PACKS_PROJECT)/worlds
	ln -sfn ../../vendor/world-packer/addons/world_packer $(PACKS_PROJECT)/addons/world_packer
	$(GODOT) --headless --path $(PACKS_PROJECT) -s res://addons/world_packer/export_world.gd -- $(WORLD) $(abspath $(PACKS_OUT))
	cd $(PACKS_OUT) && rm -f $(WORLD).zip && zip -r $(WORLD).zip worlds/$(WORLD) worlds/$(WORLD).json
