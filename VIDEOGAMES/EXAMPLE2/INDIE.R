library(readr)        #Para leer e importar datos
library(dplyr)        #An�lisis exploratorio
library(ggplot2)      #Visualizaciones
library(tidyverse)    #Utilizada para ordenar dataset
library(gsheet)       #Leer google sheets
library(readxl)       
library(knitr)        #Varios prop�sitos
library(DT)           #libreria DataTables
library(caret)        #Variables para Correlation Matrix
library(grid)         #Plotear
library(gridExtra)    #Plotear
library(corrr)        #Var estadisticas
library(ggpubr)
library(qcc)
library(data.table)
library(janitor)
library(arules)
library(arulesViz)
library(lubridate)
library(stats)
library(samplingbook)
library(rmarkdown)
library(plotly)

Apertura de archivos

list.files()

DI <- read_xlsx("Task1-Test_Indie_Analytics-Sessions.xlsx")
view(head(DI,20))

Cambiamos los nombres de las variables para hacer m�s facil su referenciaci�n

names(DI)[c(1,2,3,4,5,6,7,8)]=c("user_id","ins_date","country","ses_id","ses_date","revenue","game_time","comp_lvl")

summary(DI)
glimpse(DI)

Observamos variables que no tienen la categor�a correcta y que nos pueden dar problemas en el an�lisis

DI$ins_date = as.Date(DI$ins_date)
DI$ses_date = as.Date(DI$ses_date)

Tenemos una primera visual, y posteriormente procedemos al an�lisis:
Observamos el rango de fechas y el total de paises:

min(DI$ses_date)
max(DI$ses_date)

ses_ini_date = "2019-09-05"
ses_end_date = "2019-09-15"
Un total de 11 d�as de muestreo jugado

DI %>% group_by(country) %>% summarise(n=n())

Observamos que hay usuarios de 3 pa�ses, DE, FR, GB

### Ejercicio 1:
***

1.1.1. Media Sesiones:

E1_ses_avg = DI %>% group_by(ses_date) %>%
  mutate(DE=ifelse(country=="DE",1,0),
         FR=ifelse(country=="FR",1,0),
         GB=ifelse(country=="GB",1,0)) %>%
  summarise(DE=sum(DE),
            FR=sum(FR),
            GB=sum(GB)) %>%
  summarise(DE=mean(DE),
            FR=mean(FR),
            GB=mean(GB)) %>% 
  t() %>% as.data.table()
names(E1_ses_avg)[1] = "ses_avg"

DI %>% mutate(DAY=day(ses_date)-5) %>% 
  ggplot(aes(x = "",fill=country)) +
  geom_bar(width = 1)+
  coord_polar(theta = "y")+
  scale_fill_brewer(palette = "Accent")

1.1.2. Tiempo medio jugado:

E1_time_avg = DI %>% group_by(country) %>%
  summarise(time_avg=mean(game_time/(1000*60*60))) ##calculo que lo pasamos a horas

1.1.3. Niveles completados:

E1_complvl_total = DI %>% group_by(country) %>%
  summarise(complvl_tot = sum(comp_lvl))

1.1.4. Niveles completados de media por sesi�n:

E1_complvl_avg = DI %>% group_by(ses_date) %>% 
  mutate(DE=ifelse(country=="DE",as.integer(comp_lvl),0),
         FR=ifelse(country=="FR",as.integer(comp_lvl),0),
         GB=ifelse(country=="GB",as.integer(comp_lvl),0)) %>% 
  summarise(DE=sum(DE),
            FR=sum(FR),
            GB=sum(GB)) %>%
  summarise(DE=mean(DE),
            FR=mean(FR),
            GB=mean(GB)) %>% 
  t() %>% as.data.table()
names(E1_complvl_avg)[1] = "complvl_avg"


1.1.5. Tiempo jugado por sesi�n (medio):

E1_time_ses_avg = DI %>% group_by(ses_date) %>% 
  mutate(DE=ifelse(country=="DE",game_time/(1000*60*60),0),
         FR=ifelse(country=="FR",game_time/(1000*60*60),0),
         GB=ifelse(country=="GB",game_time/(1000*60*60),0)) %>% 
  summarise(DE=sum(DE),
            FR=sum(FR),
            GB=sum(GB)) %>%
  summarise(DE=mean(DE),
            FR=mean(FR),
            GB=mean(GB)) %>% 
  t() %>% as.data.table()
names(E1_time_ses_avg)[1] = "time_ses_avg"

Es interesante, de cualquier modo, observar un histograma con el tiempo jugado por sesi�n y por pa�s:
  
  DI %>% group_by(ses_date) %>% 
  mutate(DE=ifelse(country=="DE",game_time/(1000*60*60),0),
         FR=ifelse(country=="FR",game_time/(1000*60*60),0),
         GB=ifelse(country=="GB",game_time/(1000*60*60),0)) %>% 
  summarise(DE=sum(DE),
            FR=sum(FR),
            GB=sum(GB)) %>% 
    ggplot(aes(x=ses_date),position="dodge")+ 
    geom_col(aes(y=DE),fill="salmon4")+
    geom_col(aes(y=FR),fill="blue2")+
    geom_col(aes(y=GB),fill="lightpink1")

Vemos que generalmente en Alemania existe una mayor frecuencia de tiempo en juego, seguido de Francia y bastante por debajo Gran Breta�a.
  
  
Obtenemos finalmente la tabla total con todas las variables obtenidas:
  
  E1.1 = cbind(E1_time_avg[,1],E1_ses_avg,E1_time_avg[,2],E1_time_ses_avg,E1_complvl_total[,2],E1_complvl_avg)
  
    `%DE-GB` = ((18057-9194)/9194)*100
  
La "ganadora" en general en relaci�n al consumo de tiempo, niveles completados... etc, es sin duda Alemania, que en estad�sticas como el incremento en niveles completados respecto a GB alcanza casi el 100%, sin embargo a�n no se ha analizado la cantidad de dinero gastado por usuario

Tomamos nota de algunos totales:

Tot_usr = as.integer(DI %>% distinct(user_id, .keep_all = TRUE)
                         %>% summarise(n=n()))

Tot_Pay = as.integer(DI %>% distinct(user_id, .keep_all = TRUE) %>% 
                       filter(revenue>0) %>% 
                       summarise(n=n()))

Tot_Rev = as.integer(DI %>%  summarise (Tot_Rev=sum(revenue)))

`%Tot_pay-Tot_usr`=(Tot_Pay/Tot_usr)*100

1.1.6. %pagadores:

E1_Pay_share = DI %>% group_by(country) %>% 
  mutate(Payers=ifelse(revenue>0,1,0)) %>% 
  summarise(Tot_gam=n(),`%Paying_share`=(sum(Payers)/n())*100,Tot_Rev=sum(revenue),Max_rev=max(revenue))

Lo primero a comentar es que el porcentaje de pagadores *por usuario* es bajo en general (0,32%) pero, *es eso una cifra baja realmente?*; como todo es relativo, obviamente no podemos responder a esa pregunta. En cambio cuando dividimos por paises decubrimos algo curioso y es que Alemania, que era la ganadora en cantidad de usuarios, partidas completadas y juego en general es la que posee el % de usuarios (los que hemos llamado ) cuando observamos el porcentaje de pagadores m�s bajo, si bien no el que acumula menos revenues, ya que esa estad�stica se la lleva Gran breta�a. Francia es aqu� quien m�s ingresos produce por compras in-app, no estando, en cambio, muy alejado de alemania en frecuencia de juego

1.1.7. ARPDAU (Average Revenue Per Daily Active User)

La f�rmula se calcula de la siguiente manera: daily income / daily active users, de manera que:

E1_ARPDAU = DI %>% group_by(ses_date) %>% 
  mutate(rev_DE=ifelse(country=="DE",revenue,0),
         rev_FR=ifelse(country=="FR",revenue,0),
         rev_GB=ifelse(country=="GB",revenue,0)) %>%
  summarise(ARPDAU_DE=sum(rev_DE)/n_distinct(user_id),
            ARPDAU_FR=sum(rev_FR)/n_distinct(user_id),
            ARPDAU_GB=sum(rev_GB)/n_distinct(user_id)) 

E1_ARPDAU %>% ggplot(aes(x=ses_date))+
    geom_line(aes(y=ARPDAU_DE), colour="salmon4")+
    geom_line(aes(y=ARPDAU_FR), colour="blue2")+
    geom_line(aes(y=ARPDAU_GB), colour="pink")

Y aqu�, la ganadora en m�s de un 100% de la que se encuentra por detr�s suya es Francia (de Alemania)

1.1.8. ARPU (Average Revenue Per User). Es como la ARPDAU, pero aplicada a un per�odo

La f�rmula se calcula por per�odos, en nuestro caso en los 11 d�as comprendidos en el an�lisis: total revenue / average suscribers, y adem�s asumimos que la media de suscritos en ese per�odo es el n1 total de jugadores de manera que:

E1_ARPU = DI %>% group_by(country) %>%
  summarise(ARPU=sum(revenue)/n())

No debe confundirse con la media de la ARPDAU (ya que estar�amos incurriendo en un error de proporciones):
 
   E1_ARPDAU_avg = E1_ARPDAU %>% 
  summarise(ARPDAU_DE_avg=mean(ARPDAU_DE),
            ARPDAU_FR_avg=mean(ARPDAU_FR),
            ARPDAU_GB_avg=mean(ARPDAU_GB))

1.1.8. ARPPU (Average Revenue Per Paying user). Es la ARPU cambiando el denominador por los usuarios de pago,
   
   E1_ARPPU = DI %>% group_by(country) %>%
     mutate(Payers=ifelse(revenue>0,1,0)) %>% 
     summarise(ARPPU=sum(revenue)/sum(Payers))

   E1.2 = cbind(E1_ARPU,ARPPU=E1_ARPPU$ARPPU,Pay_Share=E1_Pay_share$`%Paying_share`)  
 
N�tese que ARPU es equivalente a ARPPU * Paying Share, y efectivamente este hecho puede comprobarse multiplicando el Pay_share por el ARPPU, habiendo sido calculado por separado:

   E1.2 %>% mutate(ARPU_indirect = ARPPU*Pay_Share/100)

As� pues, la tabla completa de KPIs seg�n pa�s ser�a la siguiente:
   
   E1 = cbind(E1.1,E1.2[,-1])
   

### Ejercicio 1.2.:
***
   
   class(E1_ARPDAU)
   
   summary(as.data.table(E1_ARPDAU))
   
   E2 = DI %>% group_by(ses_date) %>%
     mutate(DE=ifelse(country=="DE",1,0),
            FR=ifelse(country=="FR",1,0),
            GB=ifelse(country=="GB",1,0)) %>%
     summarise(DAU_DE=sum(DE),
               DAU_FR=sum(FR),
               DAU_GB=sum(GB)) 
   
Una de las m�tricas m�s interesantes es la DAU, de aqu� podemos extraer algunas conclusiones interesantes cuando valoramos el tipo de distribuci�n que sigue:

E2_DAU = E2 %>% ggplot(aes(x=ses_date))+
  geom_line(aes(y=DAU_DE),color="salmon4", size=2)+
  geom_line(aes(y=DAU_FR),color="blue2", size=2)+
  geom_line(aes(y=DAU_GB),color="pink", size=2)+ 
  xlab("Sesion Date") +
  ylab("DAU")

E2_ARPDAU = E1_ARPDAU %>% ggplot(aes(x=ses_date))+
  geom_line(aes(y=ARPDAU_DE), colour="salmon4", size=2)+
  geom_line(aes(y=ARPDAU_FR), colour="blue2", size=2)+
  geom_line(aes(y=ARPDAU_GB), colour="pink", size=2)+ 
  xlab("Sesion Date") +
  ylab("ARPDAU")

grid.arrange(E2_DAU,E2_ARPDAU, nrow=1)

Y precisamente es interesante por el fen�meno que podemos observar en dicha evoluci�n. Durante la primera mitad del ejercicio era plausible pensar que en alemania se estaban cumpliendo las mejores previsiones en las m�tricas en relaci�n a la actividad de juego, ahora resumidas y condensadas en la m�trica 'DAU', de la cual puede contemplarse una evoluci�n bastante uniforme relativa a las tendencias en los 3 pa�ses, pero con un claro *"ganador"*= Alemania. Sin embargo m�s adelante hemos afinado la b�squeda teniendo en cuenta los ingresos por IAPs y aqu� hemos comprobado un *cambio en las expectativas de �xito* relativas a los pa�ses, donde Francia ha demostrado poseer los mejores resultados relativos a las m�tricas principales usadas por los grandes proveedores de KPIs de videojuegos de m�viles como Delta DNA (ARPDAU, ARPU, ARPPU...), tal como se ha reflejado en la segunda parte del ejercicio, abanderado por la Paying Share o % pagador.

Es muy interesante y digna de estudio (pero no vamos a entrar en profundidad aqu�) el desequilibrio que se observa en las tendencias de la ARPDAU en la evoluci�n de los diferentes pa�ses, sufrida principalmente por GB, de la cual hemos visto, *frente a todo pron�stico*, como ha resultado adelantar a Alemania en la tasa de pagadores, pese a tener menor contribuci�n absoluta neta (revenues) que �sta.

kable(E1)

Seg�n observamos en la consulta 1:
  - Tiempo jugado por sesi�n (time_ses_avg) --> DE > FR >> GB
  - Media de Sesiones (ses_avg) --> DE > FR >> GB

Y sin embargo,

  - ARPU --> FR >> GB > DE
  - Pay_Share --> FR > GB >> DE

En definitiva, son interesantes las *aparentes* contradicciones.

Otras m�tricas interesantes ser�an estudiar las New Users, o los llamados K-Factor (que miden la incidencia por cantidad de invitaciones lanzadas por clientes), pero faltan datos de la BBDD extra�da de los proveedores para sacar conclusiones. Y en caso de poseer estos datos se podr�a dar un paso m�s y obtener la m�trica de densidad avanzada [N� invitaciones enviadas / DAU], algo que podr�a arrojar mucha luz en la evoluci�n de los datos, incluso de aquellos que presenten aparentes contradicciones, como hemos visto al principio de la exposici�n de este apartado.

Por �ltimo, s�lo mencionar que podr�amos hacer una estimaci�n de las KPIs de retenci�n a 1, 2,3 y varios d�as en base a usuarios, dado que poseemos datos de un per�odo de 10 d�as con sus respectivas ID_session, tal como expuse en el ejercicio anterior que present� para Genera, que m�s o menos tendr�a la siguiente forma:

  KPI_ret = DI %>% mutate(DAY_ins=day(ins_date),DAY_ses=day(ses_date)) %>%
  group_by(user_id)%>%
  mutate(D1=ifelse(DAY==5,1,0),D2=ifelse(DAY==6,1,0),
         D3=ifelse(DAY==6,1,0),D4=ifelse(DAY==6,1,0)) %>%
  summarise(D1=ifelse(sum(D1)>=1,1,0),
            D2=ifelse(sum(D2)>=1,1,0),
            D3=ifelse(sum(D3)>=1,1,0),
            D4=ifelse(sum(D4)>=1,1,0)) %>%
  mutate(RT1=ifelse((D1+D2+D3+D4)>1,1,0),RT2=ifelse((D1+D2+D3+D4)>2,1,0),RT3=ifelse((D1+D2+D3+D4)>3,1,0)) %>%
  select(user_id,RT1,RT2,RT3)


 etc....


### Ejercicio 1.3.:
***

1.3.1. Media de sesiones:

Haciendo uso de las consultas hechas anteriormente, le aplicamos filtros para d�a 0 y resto de los d�as:

E3_ses_avg = DI %>% mutate(DAY=day(ses_date)-5) %>% 
  group_by(country) %>% 
  mutate(DAY_0 = ifelse(DAY==0,1,0),
         DAY_REST=ifelse(DAY>0,1,0)) %>% 
  summarise(DAY_0=as.integer(sum(DAY_0)),
            DAY_REST=as.integer(sum(DAY_REST)/10),
            `INCREASE(%)`=((DAY_REST-DAY_0)/DAY_0)*100)

Francia ha tenido un incremento en media de sesiones de casi el 35%, pero en general como vemos se ha incrementado en todos los pa�ses.

1.3.2. Tiempo jugado por sesi�n (medio):

E3_time_ses_avg = DI %>%
  mutate(DAY=day(ses_date)-5) %>%
  group_by(country) %>% 
  mutate(DAY_0=ifelse(DAY==0,game_time/(1000*60*60),0),
         DAY_REST=ifelse(DAY>0,game_time/(1000*60*60),0)) %>% 
  summarise(DAY_0=sum(DAY_0),
            DAY_REST=sum(DAY_REST)/10,
            `INCREASE(%)`=((DAY_REST-DAY_0)/DAY_0)*100)
  
Y efectivamente, Francia es el unico que sufre un crecimiento positivo en tiempo de juego. Esto tambi�n deja de manifiesto que la evoluci�n de la media de sesiones es independiente a la evoluci�n del tiempo de juego por sesi�n; es decir, *pese a que aumente la media de sesiones en el tiempo, no implica que ello provoque un aumento en el tiempo medio de dichas sesiones*. En el caso de francia habr�a que estudiarlo m�s a fondo como haremos en el an�lisis exploratorio.

### Ejercicio 4:
***

Pese a que se ya ha estado haciendo un an�lisis e interpretaci�n de datos en el camino, vayamos m�s a fondo en algunas cuestiones:
  
4.1. An�lisis del incremento y decremento en la evoluci�n media de sesiones y tiempo medio de las mismas:

Tal como hemos visto en el ejercicio 3, vamos a **normalizar** ambas estad�sticas para que podamos verlas reflejadas en un mismo gr�fico:

  row_ses = cbind(E3_ses_avg[,2]/colMeans(E3_ses_avg[,2]),E3_ses_avg[,3]/colMeans(E3_ses_avg[,3]))
  colnames(row_ses)=c("DAY_ses","DAY_ses")

  row_ses %>% gather(key=DAY_ses)
  
  row_time = cbind(E3_time_ses_avg[,2]/colMeans(E3_time_ses_avg[,2]),E3_time_ses_avg[,3]/colMeans(E3_time_ses_avg[,3]))
  colnames(row_time)=c("DAYtime","DAYtime")

Pero hag�moslo con la evoluci�n de d�as:
    
    E4.1 = DI %>% group_by(ses_date) %>% 
      mutate(DE_ses=ifelse(country=="DE",1,0),
             FR_ses=ifelse(country=="FR",1,0),
             GB_ses=ifelse(country=="GB",1,0),
             DE_time=ifelse(country=="DE",game_time/(1000*60*60),0),
             FR_time=ifelse(country=="FR",game_time/(1000*60*60),0),
             GB_time=ifelse(country=="GB",game_time/(1000*60*60),0)) %>% 
      summarise(DE_ses=sum(DE_ses),
                FR_ses=sum(FR_ses),
                GB_ses=sum(GB_ses),
                DE_time=sum(DE_time),
                FR_time=sum(FR_time),
                GB_time=sum(GB_time)) %>% 
      ggplot(aes(x=ses_date),position="dodge")+
      geom_line(aes(y=DE_ses),color="salmon4",size=2)+
      geom_line(aes(y=FR_ses),color="blue3",size=2)+
      geom_line(aes(y=GB_ses),color="red",size=2)+      
      geom_line(aes(y=DE_time),color="salmon1",size=2)+
      geom_line(aes(y=FR_time),color="lightblue",size=2)+
      geom_line(aes(y=GB_time),color="lightpink",size=2)+
      xlab("Sesion Date") +
      ylab("Ev Sesion-Sesiontime")

O normalizado:
    
    E4.2 = DI %>% group_by(ses_date) %>% 
      mutate(DE_ses=ifelse(country=="DE",1,0),
             FR_ses=ifelse(country=="FR",1,0),
             GB_ses=ifelse(country=="GB",1,0),
             DE_time=ifelse(country=="DE",game_time/(1000*60*60),0),
             FR_time=ifelse(country=="FR",game_time/(1000*60*60),0),
             GB_time=ifelse(country=="GB",game_time/(1000*60*60),0)) %>% 
      summarise(DE_ses=sum(DE_ses/(n()/11)),
                FR_ses=sum(FR_ses/(n()/11)),
                GB_ses=sum(GB_ses/(n()/11)),
                DE_time=sum(DE_time/(n()/11)),
                FR_time=sum(FR_time/(n()/11)),
                GB_time=sum(GB_time/(n()/11))) %>% 
      ggplot(aes(x=ses_date),position="dodge")+
      geom_line(aes(y=DE_ses),color="salmon4",size=2)+
      geom_line(aes(y=FR_ses),color="blue3",size=2)+
      geom_line(aes(y=GB_ses),color="red",size=2)+      
      geom_line(aes(y=DE_time),color="salmon1",size=2)+
      geom_line(aes(y=FR_time),color="lightblue",size=2)+
      geom_line(aes(y=GB_time),color="lightpink",size=2)+
      xlab("Sesion Date") +
      ylab("Ev Sesion-Sesiontime normalized")
    
    grid.arrange(E4.1,E4.2, nrow=1)

Donde los colores fuertes se refieren a las sesiones medias y los colores suaves a los *tiempos medios por sesi�n*. Aqu� los incrementos que hemos calculado en el E3 no son tan visibles, y eso se debe a que el incremento percibido en lo que hemos considerado "DAY_REST", o d�as diferentes al D�a 0, se concentran principalmente en unos picos percibidos en los d�as 3-4-5, para despu�s caer por debajo incluso del d�a 0. Se puede estimar, a partir de estos gr�ficos como la KPI de retenci�n a d�as comienza a decaer a partir de los 4-5 d�as desde la primera sesi�n. En la gr�fica normalizada vemos una mayor estabilidad en los resultados ya que debido a su naturaleza lo que muestra es una tendencia m�s a largo plazo, y es l�gico que no veamos cambios significativos.

Aqu� por ejemplo vamos a estudiar la distribuci�n de suscriptores que hay en relaci�n a la cantidad de d�as (retenci�n) que llevan jugando desde que instalaron el juego:
    
E5.2 = DI %>% group_by(ses_id) %>% 
  distinct(ses_id, .keep_all = TRUE) %>% 
  summarise(first_date=min(ins_date),
              last_date=max(ses_date),
              NumDays=last_date-ins_date)

  E5.2 %>% ggplot(aes(x = factor(1), fill = factor(NumDays))) +
  geom_bar(width = 1)+
  coord_polar(theta = "y")+
  theme_minimal()+
  xlab("Cantidad de d�as en la 'red' ")+
  ylab("Cantidad de suscriptores")

  Aqu� podemos observar el n�mero de sesiones abiertas y cantidad de d�as permanecidos abriendo sesiones por ID de sesi�n. Todo tiene un aspecto relativamente normal

 DI %>% group_by(ses_id) %>% 
    distinct(ses_id, .keep_all = TRUE) %>% 
    summarise(n=sum(comp_lvl)) %>% 
    ggplot(aes(x=factor(n),fill=n))+
   scale_fill_gradient(low = "lightblue", high = "navy")+
    geom_bar(width=0.7)+
   coord_flip()+
   xlab("Cantidad de niveles completados")+
   ylab("Cantidad de suscriptores")

 # Sigue una distribuci�n exponencial decreciente de usuarios, sin saltos destacables tampoco, excepto por el hecho de a partir de los 6-7 niveles completados el n�mero de usuarios con probabilidad de �xito disminuye vertiginosamente.
 

 
 
 
 
 ### Ejercicio 2:
 ***

 2.3. An�lisis exploratorio
 
 DL <- read_xlsx("Task2-Test_Indie_Analytics-IAPs.xlsx")
 view(head(DL,20))
 
 # Cambiamos los nombres de las variables para hacer m�s facil su referenciaci�n
 
 names(DL)[c(1,2,3,4,5,6,7)]=c("user_id","ins_date","country","platform","purchase_date","IAP","purchase")

 Observamos variables que no tienen la categor�a correcta y que nos pueden dar problemas en el an�lisis
 
 Tot_usr2 = as.integer(DL %>% distinct(user_id, .keep_all = TRUE)
                      %>% summarise(n=n()))
 
 DL$ins_date = as.Date(DL$ins_date)
 DL$purchase_date = as.Date(DL$purchase_date)
 
 summary(DL)
 glimpse(DL)
 
 Tenemos una primera visual, y posteriormente procedemos al an�lisis:
 
 Tot_Period = as.integer(max(DL$purchase_date) - min(DL$purchase_date))

 Un total de 73 d�as de muestreo jugado
 
 U1.1 = DL %>% group_by(country) %>% 
   summarise(n=n()) %>%     
   ggplot(aes(x=country, y=n,fill=n)) +
   geom_bar(stat="identity", width=0.8)+
   scale_fill_gradient(low = "lightblue", high = "navy")+
   xlab("Pa�ses")+
   ylab("Cantidad de suscriptores")

 DL %>% group_by(country) %>% 
   summarise(n=n()) %>% summary()
 
Aqu� observamos que tenemos un total de 10 pa�ses contemplados en el an�lisis, donde claramente el Estados Unidos quien lidera con casi 2000 suscriptores registrados en el per�odo contemplado seguido de Alemania con casi 900 y el resto de pa�ses que ya se encuentran en el percentil 50% por debajo de 200 suscriptores.

U1.2 = DL %>% distinct(user_id, .keep_all = TRUE) %>% 
  group_by(platform) %>% 
  summarise(n=n_distinct(user_id),`%`=(n_distinct(user_id)/Tot_usr2)*100)

DL %>% ggplot(aes(x = factor(1), fill = factor(platform))) +
  geom_bar(width = 1)+
  coord_polar(theta = "y")+
  theme_minimal()

Y Android como sistema operativo l�der (con una cuota mayor al 95%)

A continuaci�n exploramos la tabla al completo. Haremos un primer chequeo en la relaci�n de la cantidad de comprar s/ d�a:
  
DL %>% ggplot(aes(x=purchase_date,y=purchase))+
  geom_line()

Conforme avanza el a�o las compras aumentan de m�ximos, pero desconocemos su densidad:

DL %>% mutate(purchase_month=month(purchase_date)) %>% 
  group_by(purchase_month) %>%  
  ggplot(aes(x = factor(1), fill = factor(purchase_month))) +
  geom_bar(width = 1)+
  coord_polar(theta = "y")+
  theme_minimal()

El mes de septiembre aglutina la mayor�a absoluta de compras desde que se comenz� el an�lisis, claro que esto no es fidedigno ya que el mes de agosto comienza a contar casi a mitad de mes, de manera que calculamos la densidad de compras por usuarios al mes, o dicho de otro modo, al ARPU

DL %>% mutate(purchase_month=month(purchase_date)) %>% 
  group_by(purchase_month) %>%
  summarise(ARPU=sum(purchase)/n())

DL %>% mutate(purchase_month=month(purchase_date)) %>% 
  group_by(purchase_month) %>%
  summarise(ARPU=sum(purchase)/n()) %>% 
  ggplot(aes(x=purchase_month, y=ARPU,fill=ARPU)) +
  geom_bar(stat="identity", width=0.8)+
  scale_fill_gradient(low = "lightgreen", high = "Green4")+
  xlab("Mes")+
  ylab("ARPU")

Ahora s�, comprobamos que efectivamente en agosto es cuando hay mayor densidad de compras, quiz�s tenga que ver con el hecho de que la gente tiene m�s tiempo libre de vacaciones y puede jugar m�s, y poco a poco decrece

Exploramos tambi�n la cantidad de IAPs y su frecuencia de compra:

U3.1 =DL %>% group_by(IAP) %>% 
  summarise(quantity=n(),
            gain=sum(purchase),
            effect=sum(purchase)/n()) %>% 
  arrange(effect)

summary(U3.1)

Ah� tenemos un orden de la rentabilidad econ�mica de los diferentes IAPs, en los que el pack5 parece que es el que tiene mayor rentabilidad pero no es representativo, ya que se ha consumido muy poco, de manera que hacemos limpieza de los IAP que consideremos despreciables, bas�ndonos en la cantidad correspondiente al primer cuartil, 23 unidades, y queda lo siguiente:

U3.1 = U3.1 %>% filter(quantity>23)
  
summary(U3.1)  

U3.1 %>% ggplot(aes(x=IAP, y=effect,fill=effect)) +
  geom_bar(stat="identity", width=0.8) +
  scale_fill_gradient(low = "lightblue", high = "navy") +
  xlab("IAP") +
  ylab("Rentabilidad") +
  geom_hline(yintercept=mean(U3.1$effect), linetype="dashed", color="red", size=2)+
geom_hline(yintercept=quantile(U3.1$effect,probs = 0.25), linetype="dashed", color="violet", size=1.5)

Donde el Pack1 gana por goleada absoluta, teniendo el r�cord en ganancias y en rentabilidad, as� como cantidad consumida. En base a lo observado aqu�, y con tal de simplificar un poco el an�lisis posterior, vamos a agrupar los IAP en 3 grupos:
- Grupo 1 (Correspondiente a los m�s rentables): Pack1, 0, 3 y 2
- Grupo 2 (Correspondiente a los medios (se encuentran entre media y quartil 25%)): SpecialPacks
- Grupo 3 (Correspondiente a los menos rentables): PiggyBanks

2.1.1. M�tricas por pa�s

U2.1.1 = DL %>% group_by(country) %>% 
  mutate(AND=ifelse(platform=="ANDROID",1,0),
         IOS=ifelse(platform=="IOS",1,0),
         G1=ifelse(IAP=="Pack0" | IAP=="Pack1" | IAP=="Pack2" | IAP=="Pack3",1,0),
         G2=ifelse(IAP=="SpecialPack0" | IAP=="SpecialPack1" | IAP=="SpecialPack2" ,1,0),
         G3=ifelse(IAP=="Pack4" | IAP=="Pack5" | IAP=="Pack6" | IAP=="SpecialPack3" | IAP=="PiggyBank1" | IAP=="PiggyBank2" ,1,0)) %>% 
  summarise(pref_plat=ifelse(sum(AND)>sum(IOS),"ANDROID","IOS"),
            tot_purch=sum(purchase),
            freq_purch_sub=sum(purchase)/n(), ###frecuencia por suscripci�n o jugada
            freq_purch=sum(purchase)/n_distinct(user_id), ##Frecuencia por cantidad de usuarios totales
            G1_rate=sum(G1)/n(),
            G2_rate=sum(G2)/n(),
            G3_rate=sum(G3)/n()) %>% 
  arrange(G3_rate)
  

Esta tabla completa arroja una series de datos muy interesantes. En orden descendente (de mayor a menor, valoramos las siguientes m�tricas)
  - tot_purch: US >> DE > FR >> rest
  - freq_purch: FR > SE > CA
  - G1_rate: GB > FR > SE
  - G2_rate: DK > CA > CH
  - G3_rate: CH > US > DK

U2.1.1.totpurch = U2.1.1 %>% ggplot(aes(x=country, y=tot_purch,fill=tot_purch)) +
  geom_bar(stat="identity", width=0.8) +
  scale_fill_gradient(low = "lightgreen", high = "green4") +
  xlab("Pa�s") +
  ylab("Total de compras")

U2.1.1.freq_purch = U2.1.1 %>% ggplot(aes(x=country, y=freq_purch,fill=freq_purch)) +
  geom_bar(stat="identity", width=0.8) +
  scale_fill_gradient(low = "lightblue", high = "navy") +
  xlab("Pa�s") +
  ylab("Frecuencia de compras")

U2.1.1.freq_purch_sub = U2.1.1 %>% ggplot(aes(x=country, y=freq_purch_sub,fill=freq_purch_sub)) +
  geom_bar(stat="identity", width=0.8) +
  scale_fill_gradient(low = "plum", high = "purple4") +
  xlab("Pa�s") +
  ylab("Frecuencia de compras por suscriptor o jugada")

U2.1.1.G1_rate = U2.1.1 %>% ggplot(aes(x=country, y=G1_rate,fill=G1_rate)) +
  geom_bar(stat="identity", width=0.8) +
  scale_fill_gradient(low = "lightgoldenrod1", high = "lightgoldenrod4") +
  xlab("Pa�s") +
  ylab("Ratio de IAPs del Grupo 1")

U2.1.1.G2_rate = U2.1.1 %>% ggplot(aes(x=country, y=G2_rate,fill=G2_rate)) +
  geom_bar(stat="identity", width=0.8) +
  scale_fill_gradient(low = "gray90", high = "grey47") +
  xlab("Pa�s") +
  ylab("Ratio de IAPs del Grupo 2")

U2.1.1.G3_rate = U2.1.1 %>% ggplot(aes(x=country, y=G3_rate,fill=G3_rate)) +
  geom_bar(stat="identity", width=0.8) +
  scale_fill_gradient(low = "bisque1", high = "bisque4") +
  xlab("Pa�s") +
  ylab("Ratio de IAPs del Grupo 3")

grid.arrange(U2.1.1.totpurch,U2.1.1.freq_purch,U2.1.1.freq_purch_sub,U2.1.1.G1_rate,U2.1.1.G2_rate,U2.1.1.G3_rate, nrow=2)

Tras la exposici�n de datos y gr�ficos, sumariamos lo siguiente:
  - En el total de compras US gana muy por encima de la media, pero este dato generalmente no es un buen indicador ya que las est�disticas nunca se miden en t�rminos absolutos, por el simple hecho de que US tiene mayor poblaci�n objetiva que el resto de pa�ses que se analizan. Dicho esto, es un pa�s objetivo importante
  - Seg�n la frecuencia de compras, que probablemente es la m�trica m�s importante, Francia est� por encima de los dem�s, seguido de cerca de Suecia y finalmente seguido de Canad�. Parece que los pa�ses Franco-parlantes son un p�blico objetivo.
  - Seg�n los ratios de IAPs del grupo 1, que son los importantes y en los que apuntaremos comentarios, decir que Gran Breta�a se encuentra a la cabeza, seguido, de nuevo, de Francia y Suecia.

Conclusiones:
  - Francia es el activo m�s importante como pa�s, y donde, suponemos, se encuentra el p�blico objetivo m�s importante a salvaguardar.
  - Suecia tiene un potencial similar, pese a que no reporta grandes beneficios en t�rminos absolutos.
  - Estados unidos y Alemania, como ya vimos tambi�n en el ejercicio anterior, son activos muy importantes no por el factor *calidad*, si no m�s bien por el de cantidad. Merecen una atenci�n especial igualmente.
  - Finalmente, GB parece ser uno de los activos crecientes con m�s potencial. Arrojando los mejores resultados en el consumo de IAPs de mayor rentabilidad (grupo 1), tambi�n tiene valores altos en casi todos los ratios, podr�a situarse a la cabeza en los pr�ximos a�os si se sigue trabajando en las necesidades objetivas del p�blico brit�nico.

2.1.2. M�tricas por plataforma

Sobre las m�tricas por plataforma no har� gran hincapi� ya que, como hemos visto, el uso de los videojuegos en plataformas IOS no supera apenas el 5% de los usuarios totales, lo que convierte el an�lisis de cualquier m�trica relativamente *despreciable*, estad�sticamente hablando.



2.2. Ejercicio 2: M�tricas por d�a 0 vs resto

summary(DL)

Calculamos el N� de d�as totales en los que se hace el an�lisis

  Tot_days = as.integer(max(DL$purchase_date)-min(DL$purchase_date))

DL2 = DL %>% mutate(DAY=as.integer(purchase_date-min(purchase_date)))

U3.1 = DL2 %>% group_by(country) %>% 
  filter(DAY<2) %>% 
  mutate(AND=ifelse(platform=="ANDROID",1,0),
         IOS=ifelse(platform=="IOS",1,0),
         G1=ifelse(IAP=="Pack0" | IAP=="Pack1" | IAP=="Pack2" | IAP=="Pack3",1,0),
         G2=ifelse(IAP=="SpecialPack0" | IAP=="SpecialPack1" | IAP=="SpecialPack2" ,1,0),
         G3=ifelse(IAP=="Pack4" | IAP=="Pack5" | IAP=="Pack6" | IAP=="SpecialPack3" | IAP=="PiggyBank1" | IAP=="PiggyBank2" ,1,0)) %>% 
  summarise(pref_plat=ifelse(sum(AND)>sum(IOS),"ANDROID","IOS"),
            tot_purch=sum(purchase)/(2),
            freq_purch=sum(purchase)/n_distinct(user_id), ##Frecuencia por cantidad de usuarios totales
            G1_rate=sum(G1)/n(),
            G2_rate=sum(G2)/n(),
            G3_rate=sum(G3)/n()) %>% 
  arrange(G3_rate)

Escojo como el *d�a 0* hasta el d�a 2 del muestreo, ya que el primer d�a apenas se incorporan pa�ses, y es una manera simplificada de hacerlo, pese a que se podr�a seleccionar dia 0 por cada pa�s:

U3.2 = DL2 %>% group_by(country) %>% 
  filter(DAY>1) %>% 
  mutate(AND=ifelse(platform=="ANDROID",1,0),
         IOS=ifelse(platform=="IOS",1,0),
         G1=ifelse(IAP=="Pack0" | IAP=="Pack1" | IAP=="Pack2" | IAP=="Pack3",1,0),
         G2=ifelse(IAP=="SpecialPack0" | IAP=="SpecialPack1" | IAP=="SpecialPack2" ,1,0),
         G3=ifelse(IAP=="Pack4" | IAP=="Pack5" | IAP=="Pack6" | IAP=="SpecialPack3" | IAP=="PiggyBank1" | IAP=="PiggyBank2" ,1,0)) %>% 
  summarise(pref_plat=ifelse(sum(AND)>sum(IOS),"ANDROID","IOS"),
            tot_purch=sum(purchase/(Tot_days-2)),
            freq_purch=(sum(purchase)/n_distinct(user_id)), ##Frecuencia por cantidad de usuarios totales, que tenemos que dividir por 72, para que podamos comparar datos
            G1_rate=sum(G1)/n(),
            G2_rate=sum(G2)/n(),
            G3_rate=sum(G3)/n()) %>% 
  arrange(G3_rate)

Es dif�cil valorar los datos, pese a que lo importante aqu� son los ratios relativos a la poblaci�n completa

Vemos m�tricas del D�a 0:

U3.1.totpurch = U3.1 %>% ggplot(aes(x=country, y=tot_purch,fill=tot_purch)) +
  geom_bar(stat="identity", width=0.8) +
  scale_fill_gradient(low = "lightgreen", high = "green4") +
  xlab("Pa�s") +
  ylab("Total de compras")

U3.1.freq_purch = U3.1 %>% ggplot(aes(x=country, y=freq_purch,fill=freq_purch)) +
  geom_bar(stat="identity", width=0.8) +
  scale_fill_gradient(low = "lightblue", high = "navy") +
  xlab("Pa�s") +
  ylab("Frecuencia de compras")

U3.1.freq_purch_sub = U3.1 %>% ggplot(aes(x=country, y=freq_purch_sub,fill=freq_purch_sub)) +
  geom_bar(stat="identity", width=0.8) +
  scale_fill_gradient(low = "plum", high = "purple4") +
  xlab("Pa�s") +
  ylab("Frecuencia de compras por suscriptor o jugada")

U3.1.G1_rate = U3.1 %>% ggplot(aes(x=country, y=G1_rate,fill=G1_rate)) +
  geom_bar(stat="identity", width=0.8) +
  scale_fill_gradient(low = "lightgoldenrod1", high = "lightgoldenrod4") +
  xlab("Pa�s") +
  ylab("Ratio de IAPs del Grupo 1")

U3.1.G2_rate = U3.1 %>% ggplot(aes(x=country, y=G2_rate,fill=G2_rate)) +
  geom_bar(stat="identity", width=0.8) +
  scale_fill_gradient(low = "gray90", high = "grey47") +
  xlab("Pa�s") +
  ylab("Ratio de IAPs del Grupo 2")

U3.1.G3_rate = U3.1 %>% ggplot(aes(x=country, y=G3_rate,fill=G3_rate)) +
  geom_bar(stat="identity", width=0.8) +
  scale_fill_gradient(low = "bisque1", high = "bisque4") +
  xlab("Pa�s") +
  ylab("Ratio de IAPs del Grupo 3")

grid.arrange(U3.1.totpurch,U3.1.freq_purch,U3.1.G1_rate,U3.1.G2_rate,U3.1.G3_rate, nrow=2,top="DAY 0")

Vemos m�tricas del resto de d�as:

U3.2.totpurch = U3.2 %>% ggplot(aes(x=country, y=tot_purch,fill=tot_purch)) +
  geom_bar(stat="identity", width=0.8) +
  scale_fill_gradient(low = "lightgreen", high = "green4") +
  xlab("Pa�s") +
  ylab("Total de compras")

U3.2.freq_purch = U3.2 %>% ggplot(aes(x=country, y=freq_purch,fill=freq_purch)) +
  geom_bar(stat="identity", width=0.8) +
  scale_fill_gradient(low = "lightblue", high = "navy") +
  xlab("Pa�s") +
  ylab("Frecuencia de compras")

U3.2.freq_purch_sub = U3.2 %>% ggplot(aes(x=country, y=freq_purch_sub,fill=freq_purch_sub)) +
  geom_bar(stat="identity", width=0.8) +
  scale_fill_gradient(low = "plum", high = "purple4") +
  xlab("Pa�s") +
  ylab("Frecuencia de compras por suscriptor o jugada")

U3.2.G1_rate = U3.2 %>% ggplot(aes(x=country, y=G1_rate,fill=G1_rate)) +
  geom_bar(stat="identity", width=0.8) +
  scale_fill_gradient(low = "lightgoldenrod1", high = "lightgoldenrod4") +
  xlab("Pa�s") +
  ylab("Ratio de IAPs del Grupo 1")

U3.2.G2_rate = U3.2 %>% ggplot(aes(x=country, y=G2_rate,fill=G2_rate)) +
  geom_bar(stat="identity", width=0.8) +
  scale_fill_gradient(low = "gray90", high = "grey47") +
  xlab("Pa�s") +
  ylab("Ratio de IAPs del Grupo 2")

U3.2.G3_rate = U3.2 %>% ggplot(aes(x=country, y=G3_rate,fill=G3_rate)) +
  geom_bar(stat="identity", width=0.8) +
  scale_fill_gradient(low = "bisque1", high = "bisque4") +
  xlab("Pa�s") +
  ylab("Ratio de IAPs del Grupo 3")

grid.arrange(U3.2.totpurch,U3.2.freq_purch,U3.2.G1_rate,U3.2.G2_rate,U3.2.G3_rate, nrow=2,top="DAY REST")

