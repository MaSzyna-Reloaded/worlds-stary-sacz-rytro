# The world stary_sacz: its sources in worlds/<WORLD>/, where the game's packs have them, its metadata
# worlds/<WORLD>/description.tres (world-packer's WorldDescription) - written by the scenery importer
# (this repository in its sources folder), viewed in this Godot project, packed by world-packer
# (vendor/world-packer), which makes the game's worlds/<WORLD>.json of the metadata.

WORLD:=stary_sacz
# The checkouts linked into this project (make links) are given explicitly - there is no default:
# LIBMASZYNA (libmaszyna: its addons/libmaszyna, its vendor/gnd-sfx, its demo's built
# bin/libmaszyna), GND_BIOMES (godot-biomes: its addons/gnd_biomes) and WORLD_ASSETS (the world
# assets: what the worlds share, linked for this project's editor - the game mounts their packs), e.g.
#   make links LIBMASZYNA=<libmaszyna> GND_BIOMES=<godot-biomes> WORLD_ASSETS=<world-assets>
# Terrain3D is reloaded-terrain's release (make terrain3d, which make links runs).
# make packs needs none of them.
GODOT?=godot-double
# The make variable $(1) given, else make stops saying what it is ($(2)) and how to give it
require=$(if $($(1)),,$(error $(1) not given: $(2) - make $@ $(1)=<path>))

.PHONY: links editor packs world-name terrain3d

# Terrain3D, patched and built double precision, and the worlds' terrain streamer: the release
# RELOADED_TERRAIN of reloaded-terrain (github.com/MaSzyna-Reloaded/reloaded-terrain, tags
# YYMMDDHHMM) - its reloaded-terrain-<tag>.zip, addons/terrain_3d and addons/reloaded_terrain, unzipped here
RELOADED_TERRAIN:=2610152101
RELOADED_TERRAIN_ZIP:=https://github.com/MaSzyna-Reloaded/reloaded-terrain/releases/download/$(RELOADED_TERRAIN)/reloaded-terrain-$(RELOADED_TERRAIN).zip
terrain3d:
	curl -fsSL -o .reloaded-terrain.zip $(RELOADED_TERRAIN_ZIP)
	unzip -qo .reloaded-terrain.zip
	rm .reloaded-terrain.zip


# The world's name, for the CI's release
world-name:
	@echo $(WORLD)

# The addons of the other repositories and the world assets, linked as the world assets link theirs
links: terrain3d
	$(call require,LIBMASZYNA,the libmaszyna checkout linked into this project)
	$(call require,GND_BIOMES,the godot-biomes checkout linked into this project)
	$(call require,WORLD_ASSETS,the world assets checkout whose world_assets are linked)
	mkdir -p addons bin
	ln -sfn $(LIBMASZYNA)/addons/libmaszyna addons/libmaszyna
	ln -sfn $(LIBMASZYNA)/vendor/gnd-sfx/addons/gnd_sfx addons/gnd_sfx
	ln -sfn $(LIBMASZYNA)/demo/bin/libmaszyna bin/libmaszyna
	ln -sfn $(GND_BIOMES)/addons/gnd_biomes addons/gnd_biomes
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
