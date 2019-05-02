{
  "nbformat": 4,
  "nbformat_minor": 0,
  "metadata": {
    "colab": {
      "name": "Multiple Regression-R.ipynb",
      "version": "0.3.2",
      "provenance": [],
      "collapsed_sections": [],
      "include_colab_link": true
    },
    "language_info": {
      "codemirror_mode": "r",
      "file_extension": ".r",
      "mimetype": "text/x-r-source",
      "name": "R",
      "pygments_lexer": "r",
      "version": "3.3.1"
    },
    "kernelspec": {
      "display_name": "R",
      "language": "R",
      "name": "ir"
    }
  },
  "cells": [
    {
      "cell_type": "markdown",
      "metadata": {
        "id": "view-in-github",
        "colab_type": "text"
      },
      "source": [
        "<a href=\"https://colab.research.google.com/github/ehud/Notes/blob/master/Multiple_Regression.R\" target=\"_parent\"><img src=\"https://colab.research.google.com/assets/colab-badge.svg\" alt=\"Open In Colab\"/></a>"
      ]
    },
    {
      "cell_type": "markdown",
      "metadata": {
        "id": "-juw58NDV4HR",
        "colab_type": "text"
      },
      "source": [
        "# Using multiple regression to statistically control for a variable\n",
        "\n",
        "Based on the example here: https://stats.stackexchange.com/questions/17336/how-exactly-does-one-control-for-other-variables\n",
        "\n",
        "For more on the topic see: https://stats.stackexchange.com/questions/78816/how-do-you-control-for-a-factor-variable and http://methods.sowi.uni-mannheim.de/publications/Gschwend03StatisticalControl_UncorrectedVersion.pdf. \n",
        "\n",
        "Note that the specific statistical techniques are not important for us. The key is to see what happens when we have confounding variables and to see how we can use artificial data to explore questions about how to interpret evidence.\n",
        "\n",
        "The idea behind what we do here is that we create data (\"simulate the data\") so we know the real relations between the variables. We then study the data statistically, and see if we can discover the correct relations."
      ]
    },
    {
      "cell_type": "markdown",
      "metadata": {
        "id": "v8VKxPfsW1qu",
        "colab_type": "text"
      },
      "source": [
        "# Simulate the data\n",
        "\n",
        "First we create a list of numbers, each is 0 or 1 (with equal probability). This variable is the \"common cause\" - it will affect both whether the patien is exposed to the danger (making him sick indirectly) and whether the patient is sick directly."
      ]
    },
    {
      "cell_type": "code",
      "metadata": {
        "id": "0G2_vCKrTsfu",
        "colab_type": "code",
        "colab": {}
      },
      "source": [
        "covariate <- sample(0:1, 100, replace=TRUE)\n"
      ],
      "execution_count": 0,
      "outputs": []
    },
    {
      "cell_type": "code",
      "metadata": {
        "id": "uHMLudg0XkEs",
        "colab_type": "code",
        "colab": {}
      },
      "source": [
        "# uncomment the line below to see what the value of covariate variable  \n",
        "#covariate "
      ],
      "execution_count": 0,
      "outputs": []
    },
    {
      "cell_type": "markdown",
      "metadata": {
        "id": "Icg7LoRyX4n0",
        "colab_type": "text"
      },
      "source": [
        "Next we create the data on exposure to the danger. This is modeled as follows: a uniform random number between 0 and 1 (that's what the runif function returns) to which we add 0.3 or 0 depending on the corresponding value in the covariate list we created in the previous step."
      ]
    },
    {
      "cell_type": "code",
      "metadata": {
        "id": "DmEuKSt9TxNd",
        "colab_type": "code",
        "colab": {}
      },
      "source": [
        "exposure  <- runif(100,0,1)+(0.3*covariate)"
      ],
      "execution_count": 0,
      "outputs": []
    },
    {
      "cell_type": "code",
      "metadata": {
        "id": "yoV2Y-7NYRAH",
        "colab_type": "code",
        "colab": {}
      },
      "source": [
        "# uncomment the line below to see what the value of covariate variable  \n",
        "#exposure "
      ],
      "execution_count": 0,
      "outputs": []
    },
    {
      "cell_type": "markdown",
      "metadata": {
        "id": "IXQl0RPAYVci",
        "colab_type": "text"
      },
      "source": [
        "Finally we create the list of patient outcomes. The outcome is equal to 2 plus the effect of the exposure (multiplied by 0.5 ) and the direct effect of the covariate (multiplied by 0.25).\n",
        "\n",
        "The numbers multiplied by are arbitrary, they just refer to some possible effect of the variables on one another."
      ]
    },
    {
      "cell_type": "code",
      "metadata": {
        "id": "zLAM5W6aT2jy",
        "colab_type": "code",
        "colab": {}
      },
      "source": [
        "outcome   <- 2.0+(0.5*exposure)+(0.25*covariate)"
      ],
      "execution_count": 0,
      "outputs": []
    },
    {
      "cell_type": "code",
      "metadata": {
        "id": "dMvVIai7YyRx",
        "colab_type": "code",
        "colab": {}
      },
      "source": [
        "# uncomment the line below to see what the value of covariate variable  \n",
        "#outome "
      ],
      "execution_count": 0,
      "outputs": []
    },
    {
      "cell_type": "markdown",
      "metadata": {
        "id": "0EDJc5ffY0Uz",
        "colab_type": "text"
      },
      "source": [
        "# Exploring the data\n",
        "\n",
        "What we have now in the outcome variable is symptom of the patient. We also know the exposure and the covariate.\n",
        "\n",
        "We first try to find the regression line of the exposure on the outcome."
      ]
    },
    {
      "cell_type": "code",
      "metadata": {
        "id": "IG6-BmOIVQOx",
        "colab_type": "code",
        "outputId": "2702217f-4fa4-4241-fdee-c882d9d0e7c3",
        "colab": {
          "base_uri": "https://localhost:8080/",
          "height": 147
        }
      },
      "source": [
        "lm(outcome~exposure)"
      ],
      "execution_count": 0,
      "outputs": [
        {
          "output_type": "display_data",
          "data": {
            "text/plain": [
              "\n",
              "Call:\n",
              "lm(formula = outcome ~ exposure)\n",
              "\n",
              "Coefficients:\n",
              "(Intercept)     exposure  \n",
              "     1.9962       0.6879  \n"
            ]
          },
          "metadata": {
            "tags": []
          }
        }
      ]
    },
    {
      "cell_type": "markdown",
      "metadata": {
        "id": "5Ej58x_ZZdh5",
        "colab_type": "text"
      },
      "source": [
        "The answer we get is wrong, since we don't take into account that both the outcome and the exposure are affected by the covariate. We need to statisically control for that (but doing so assumes we know the causal relations...)"
      ]
    },
    {
      "cell_type": "code",
      "metadata": {
        "id": "uuqYliL3VYbq",
        "colab_type": "code",
        "outputId": "d50585bb-f895-4ccb-eba5-33f4cb57b41a",
        "colab": {
          "base_uri": "https://localhost:8080/",
          "height": 147
        }
      },
      "source": [
        "lm(outcome~exposure+covariate)"
      ],
      "execution_count": 0,
      "outputs": [
        {
          "output_type": "display_data",
          "data": {
            "text/plain": [
              "\n",
              "Call:\n",
              "lm(formula = outcome ~ exposure + covariate)\n",
              "\n",
              "Coefficients:\n",
              "(Intercept)     exposure    covariate  \n",
              "       2.00         0.50         0.25  \n"
            ]
          },
          "metadata": {
            "tags": []
          }
        }
      ]
    },
    {
      "cell_type": "markdown",
      "metadata": {
        "id": "s8PGExc_Vj33",
        "colab_type": "text"
      },
      "source": [
        "Notice that once we did the correct control (which is easy to do here becuase the situation is simple, and all relations are linear) we get the correct values: the 0.5 and 0.25 that appear in the forumla we used to create the values: outcome   <- 2.0+(0.5*exposure)+(0.25*covariate)"
      ]
    }
  ]
}