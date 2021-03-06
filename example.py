import MoogTools
import matplotlib.pyplot as pyplot


fig = pyplot.figure(0)
#fig.clear()
ax = fig.add_axes([0.1, 0.1, 0.8, 0.8])

moogPyConfigFile = 'moogPy.cfg'
Moog = MoogTools.Moog(moogPyConfigFile)
Moog.lineList.writeLineLists()
Moog.parameterFile.writeParFile()
wavelength, flux = Moog.run()

ax.plot(wavelength, flux)

fig.show()



