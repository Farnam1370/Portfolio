from dataclasses import replace
from pyexpat import features
from xml.sax.handler import feature_external_ges
import numpy as np
from flask import Flask, request, jsonify, render_template,send_from_directory
import pickle
import pandas as pd
from _collections_abc import Mapping

# Create flask app
flask_app = Flask(__name__)
model = pickle.load(open("amsterdam_rent_prediction.pkl", "rb"))

@flask_app.route("/")
def Home():
    return render_template("index2.html")



@flask_app.route("/predict", methods = ["POST"])
def predict():

    df = pd.DataFrame(np.array([(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)]),
                   columns=['Apartment', 'House', 'Studio', 'Furnished', 'Unfernished',
       'Upholstered', 'Upholstered or furnished',
       'Binnenstad en Oostelijk Havengebied', 'Buitenveldert', 'IJburg',
       'Nieuw-West', 'Noord oost', 'Noord west', 'Oost', 'West', 'Zuid',
       'Zuidoost', 'room', 'area_square_meter'])
    
    type= request.form['type']
    interior= request.form['interior']
    neighborhood= request.form['neighborhood']
    room= request.form['room']
    area= request.form['area_square_meter']


    df.at[0,'room']=int(room)
    df.at[0,'area_square_meter']=int(area)

    for i in df.columns:
        if i==type:
            df.at[0,i]=1
        if i==interior:
            df.at[0,i]=1
        if i==neighborhood:
            df.at[0,i]=1

   

    prediction = model.predict(df)
    prediction = prediction[0]
    prediction = round(prediction)
    return render_template("index2.html", prediction_text = "{} Euro per month".format(prediction))
    
if __name__ == "__main__":
    flask_app.run(debug=True)