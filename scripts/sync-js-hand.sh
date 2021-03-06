# -Syncronizes the javascript packet handler (packhand_gen.js)
#  with the definitions in packets.def.
# -extracts scenarios and helpdata from Freeciv into Freeciv-web.
# -copies sound files from Freeciv to Freeciv-web. 

python generate_js_hand/generate_js_hand.py && \
cp packhand_gen.js ../freeciv-web/src/main/webapp/javascript/ && \
cp packets.js ../freeciv-web/src/main/webapp/javascript/ && \
mkdir -p ../resin/webapps/data/savegames/ && \
cp ../freeciv/freeciv/data/scenarios/*.sav ../resin/webapps/data/savegames/ && \
python3.5 helpdata_gen/helpdata_gen.py &&\
cp freeciv-helpdata.js ../freeciv-web/src/main/webapp/javascript/ && \
cp ../LICENSE.txt ../freeciv-web/src/main/webapp/docs/ &&
mkdir -p ../freeciv-web/src/main/webapp/sounds/  && \
cp ../freeciv/freeciv/data/stdsounds/*.ogg ../freeciv-web/src/main/webapp/sounds/ && \
cd soundspec-extract && python3.5 soundspec-extract.py && cp soundset_spec.js ../../freeciv-web/src/main/webapp/javascript/ && \
echo "done with sync-js-hand!"
